import { ApolloServer } from "@apollo/server";
import { startStandaloneServer } from "@apollo/server/standalone";
import { GraphQLError } from "graphql";
import mongoose from "mongoose";

const { MONGO_URI, MONGO_HOST = "mongodb", MONGO_DB = "db_ecommerce_nosql", PORT = 4000 } = process.env;

// Conexión técnica de la API (graphql_app): solo se usa para escribir la bitácora col_logs
const appConn = await mongoose.createConnection(MONGO_URI).asPromise();
const logs = appConn.db.collection("col_logs");
console.log("Conectado a MongoDB");

// Cada petición usa la cuenta de MongoDB del rol (encabezados x-db-user / x-db-pass),
// así MongoDB aplica los privilegios reales de ese rol
const cache = new Map();
async function userConn(user, pass) {
  const key = user + "\u0000" + pass;
  if (cache.has(key)) return cache.get(key);
  const uri = `mongodb://${encodeURIComponent(user)}:${encodeURIComponent(pass)}@${MONGO_HOST}:27017/${MONGO_DB}?authSource=${MONGO_DB}`;
  const conn = await mongoose.createConnection(uri, { serverSelectionTimeoutMS: 5000 }).asPromise();
  const st = await conn.db.command({ connectionStatus: 1 });
  const rol = st.authInfo.authenticatedUserRoles.map((r) => r.role).join(",") || "sin_rol";
  const entry = { db: conn.db, rol };
  cache.set(key, entry);
  return entry;
}

const R = "col_products_reviews", S = "col_shipment_tracking";
const iso = (d) => (d instanceof Date ? d.toISOString() : d ?? null);
const out = (d) => d && {
  ...d,
  id: d._id?.toString(),
  created_at: iso(d.created_at),
  estimated_delivery: iso(d.estimated_delivery),
  fecha: iso(d.fecha),
  documento_id: d.documento_id ? String(d.documento_id) : null,
  events: d.events?.map((e) => ({ ...e, date: iso(e.date) }))
};
const oid = (id) => {
  if (!mongoose.Types.ObjectId.isValid(id)) throw new GraphQLError("ID inválido", { extensions: { code: "BAD_USER_INPUT" } });
  return new mongoose.Types.ObjectId(id);
};
const isDenied = (e) => e?.code === 13 || /not authorized|unauthorized/i.test(e?.message || "");

async function audit(ctx, info, estado) {
  await logs.insertOne({
    fecha: new Date(), operacion: info.operacion, usuario: ctx.usuario, rol: ctx.rol, ip: ctx.ip,
    coleccion: info.coleccion, documento_id: info.documento_id ?? null, descripcion: info.descripcion, estado,
    datos_anteriores: info.antes ?? null, datos_nuevos: info.despues ?? null, origen: "graphql"
  });
}

// Ejecuta la operación con la cuenta del rol y deja registro en col_logs (exitoso, denegado o error)
async function run(ctx, info, fn) {
  if (!ctx.db) throw new GraphQLError("Envía los encabezados x-db-user y x-db-pass", { extensions: { code: "UNAUTHENTICATED" } });
  try {
    const { result, ...extra } = await fn(ctx.db);
    await audit(ctx, { ...info, ...extra }, "exitoso");
    return result;
  } catch (e) {
    if (e instanceof GraphQLError) throw e;
    if (isDenied(e)) {
      await audit(ctx, { ...info, descripcion: info.descripcion + " (sin privilegios)" }, "denegado");
      throw new GraphQLError(`Operación denegada para ${ctx.usuario} (${ctx.rol})`, { extensions: { code: "FORBIDDEN" } });
    }
    await audit(ctx, { ...info, descripcion: info.descripcion + ": " + e.message }, "error");
    throw new GraphQLError(e.message, { extensions: { code: "BAD_REQUEST" } });
  }
}

const typeDefs = `#graphql
  type Review { id: ID, product_id: Int!, user_id: Int, rating: Int!, title: String, comment: String, verified_purchase: Boolean, created_at: String }
  type ProductRating { product_id: Int!, promedio: Float!, total: Int! }
  type Event { status: String, location: String, date: String }
  type Shipment { id: ID!, order_id: Int!, user_id: Int!, carrier: String, tracking_number: String, status: String, estimated_delivery: String, events: [Event] }
  type Log { fecha: String, operacion: String, usuario: String, rol: String, ip: String, coleccion: String, documento_id: String, descripcion: String, estado: String, origen: String }

  type Query {
    whoami: String
    reviews(product_id: Int, minRating: Int, limit: Int = 10, offset: Int = 0): [Review]
    publicReviews(product_id: Int, limit: Int = 10, offset: Int = 0): [Review]
    productRatings(minPromedio: Float, limit: Int = 10, offset: Int = 0): [ProductRating]
    shipments(status: String, limit: Int = 10, offset: Int = 0): [Shipment]
    logs(estado: String, usuario: String, limit: Int = 20): [Log]
  }

  type Mutation {
    createReview(product_id: Int!, user_id: Int!, rating: Int!, title: String, comment: String!): Review
    updateReview(id: ID!, rating: Int, title: String, comment: String): Review
    deleteReview(id: ID!): Boolean
    updateShipmentStatus(id: ID!, status: String!, location: String!): Shipment
  }
`;

const page = (limit) => Math.min(Math.max(limit, 1), 50);

const resolvers = {
  Query: {
    whoami: (_, __, ctx) => (ctx.db ? `${ctx.usuario} (${ctx.rol}) desde ${ctx.ip}` : `sin autenticar desde ${ctx.ip}`),

    reviews: (_, { product_id, minRating, limit, offset }, ctx) =>
      run(ctx, { operacion: "READ", coleccion: R, descripcion: "Consulta de reseñas" }, async (db) => {
        const f = {};
        if (product_id != null) f.product_id = product_id;
        if (minRating != null) f.rating = { $gte: minRating };
        const docs = await db.collection(R).find(f).sort({ rating: -1 }).skip(offset).limit(page(limit)).toArray();
        return { result: docs.map(out), descripcion: `Consulta de reseñas ${JSON.stringify(f)}: ${docs.length} resultados` };
      }),

    publicReviews: (_, { product_id, limit, offset }, ctx) =>
      run(ctx, { operacion: "READ", coleccion: "vw_public_reviews", descripcion: "Consulta de reseñas públicas" }, async (db) => {
        const f = product_id != null ? { product_id } : {};
        const docs = await db.collection("vw_public_reviews").find(f).skip(offset).limit(page(limit)).toArray();
        return { result: docs.map(out) };
      }),

    // Consulta optimizada: vista agregada + filtro + paginación
    productRatings: (_, { minPromedio, limit, offset }, ctx) =>
      run(ctx, { operacion: "READ", coleccion: "vw_product_rating_summary", descripcion: "Ranking de productos por calificación" }, async (db) => {
        const f = minPromedio != null ? { promedio: { $gte: minPromedio } } : {};
        const docs = await db.collection("vw_product_rating_summary").find(f).skip(offset).limit(page(limit)).toArray();
        return { result: docs };
      }),

    shipments: (_, { status, limit, offset }, ctx) =>
      run(ctx, { operacion: "READ", coleccion: S, descripcion: "Consulta de envíos" }, async (db) => {
        const f = status ? { status } : {};
        const docs = await db.collection(S).find(f).sort({ estimated_delivery: 1 }).skip(offset).limit(page(limit)).toArray();
        return { result: docs.map(out), descripcion: `Consulta de envíos ${JSON.stringify(f)}: ${docs.length} resultados` };
      }),

    logs: (_, { estado, usuario, limit }, ctx) =>
      run(ctx, { operacion: "READ", coleccion: "col_logs", descripcion: "Consulta de la bitácora" }, async (db) => {
        const f = {};
        if (estado) f.estado = estado;
        if (usuario) f.usuario = usuario;
        const docs = await db.collection("col_logs").find(f).sort({ fecha: -1 }).limit(page(limit)).toArray();
        return { result: docs.map(out) };
      })
  },

  Mutation: {
    createReview: (_, args, ctx) =>
      run(ctx, { operacion: "CREATE", coleccion: R, descripcion: `Nueva reseña del producto ${args.product_id}` }, async (db) => {
        const fields = Object.fromEntries(Object.entries(args).filter(([, v]) => v != null));
        const doc = { ...fields, verified_purchase: false, helpful_votes: 0, created_at: new Date() };
        const { insertedId } = await db.collection(R).insertOne(doc);
        const saved = await db.collection(R).findOne({ _id: insertedId });
        return { result: out(saved), documento_id: insertedId, despues: saved };
      }),

    updateReview: (_, { id, ...changes }, ctx) =>
      run(ctx, { operacion: "UPDATE", coleccion: R, documento_id: id, descripcion: "Edición de reseña" }, async (db) => {
        const _id = oid(id);
        const antes = await db.collection(R).findOne({ _id });
        if (!antes) throw new GraphQLError("La reseña no existe", { extensions: { code: "NOT_FOUND" } });
        const set = Object.fromEntries(Object.entries(changes).filter(([, v]) => v != null));
        await db.collection(R).updateOne({ _id }, { $set: set });
        const despues = await db.collection(R).findOne({ _id });
        return { result: out(despues), documento_id: _id, antes, despues, descripcion: `Edición de reseña: ${Object.keys(set).join(", ")}` };
      }),

    deleteReview: (_, { id }, ctx) =>
      run(ctx, { operacion: "DELETE", coleccion: R, documento_id: id, descripcion: "Eliminación de reseña" }, async (db) => {
        const _id = oid(id);
        const antes = await db.collection(R).findOne({ _id });
        const { deletedCount } = await db.collection(R).deleteOne({ _id });
        return { result: deletedCount === 1, documento_id: _id, antes };
      }),

    updateShipmentStatus: (_, { id, status, location }, ctx) =>
      run(ctx, { operacion: "UPDATE", coleccion: S, documento_id: id, descripcion: `Cambio de estado del envío a ${status}` }, async (db) => {
        const _id = oid(id);
        const antes = await db.collection(S).findOne({ _id });
        if (!antes) throw new GraphQLError("El envío no existe", { extensions: { code: "NOT_FOUND" } });
        const now = new Date();
        await db.collection(S).updateOne({ _id }, {
          $set: { status, updated_at: now, ...(status === "entregado" ? { delivered_at: now } : {}) },
          $push: { events: { status, location, date: now } }
        });
        const despues = await db.collection(S).findOne({ _id });
        return { result: out(despues), documento_id: _id, antes, despues };
      })
  }
};

const server = new ApolloServer({ typeDefs, resolvers, introspection: true });
const { url } = await startStandaloneServer(server, {
  listen: { port: Number(PORT), host: "0.0.0.0" },
  context: async ({ req }) => {
    const ip = String(req.headers["x-forwarded-for"] || req.socket.remoteAddress || "").split(",")[0].trim().replace("::ffff:", "");
    const user = req.headers["x-db-user"], pass = req.headers["x-db-pass"];
    if (!user || !pass) return { ip, usuario: "anonimo", rol: "sin_rol" };
    try {
      const { db, rol } = await userConn(String(user), String(pass));
      return { ip, usuario: String(user), rol, db };
    } catch {
      throw new GraphQLError("Usuario o contraseña de MongoDB incorrectos", { extensions: { code: "UNAUTHENTICATED", http: { status: 401 } } });
    }
  }
});
console.log("GraphQL listo en " + url);
