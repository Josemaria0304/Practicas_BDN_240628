// 02_collections_schemas.js - Colecciones con validación JSON Schema
// Ejecutar: mrun 02_collections_schemas.js   (se puede repetir: crea o actualiza)
function ensure(name, schema) {
  const opts = { validator: { $jsonSchema: schema }, validationLevel: "strict", validationAction: "error" };
  if (db.getCollectionNames().includes(name)) {
    db.runCommand(Object.assign({ collMod: name }, opts));
    print("Schema actualizado: " + name);
  } else {
    db.createCollection(name, opts);
    print("Colección creada: " + name);
  }
}

// ID entero positivo que corresponde a un registro de PostgreSQL
const pgId = { bsonType: "number", minimum: 1, multipleOf: 1 };
const text = (min, max) => ({ bsonType: "string", minLength: min, maxLength: max });

ensure("col_users_adress", {
  bsonType: "object",
  title: "Direcciones de envío de los usuarios",
  required: ["user_id", "alias", "street", "ext_number", "neighborhood", "city", "state", "zip_code", "country", "is_default", "created_at"],
  properties: {
    user_id: Object.assign({ description: "tb_users.id en PostgreSQL" }, pgId),
    alias: text(2, 30),
    street: text(3, 120),
    ext_number: text(1, 10),
    int_number: { bsonType: ["string", "null"], maxLength: 10 },
    neighborhood: text(2, 80),
    city: text(2, 80),
    state: text(2, 40),
    zip_code: { bsonType: "string", pattern: "^[0-9]{5}$", description: "Código postal de 5 dígitos" },
    country: { enum: ["México"] },
    phone: { bsonType: "string", pattern: "^[0-9]{10}$" },
    references: { bsonType: "string", maxLength: 200 },
    is_default: { bsonType: "bool" },
    created_at: { bsonType: "date" }
  }
});

ensure("col_products_reviews", {
  bsonType: "object",
  title: "Reseñas de productos",
  required: ["product_id", "user_id", "rating", "comment", "created_at"],
  properties: {
    product_id: Object.assign({ description: "tb_products.id en PostgreSQL" }, pgId),
    user_id: Object.assign({ description: "tb_users.id en PostgreSQL" }, pgId),
    rating: { bsonType: "number", minimum: 1, maximum: 5, multipleOf: 1, description: "Entero de 1 a 5" },
    title: text(3, 100),
    comment: text(5, 1000),
    verified_purchase: { bsonType: "bool" },
    helpful_votes: { bsonType: "number", minimum: 0 },
    created_at: { bsonType: "date" }
  }
});

const shipmentStatus = ["creado", "en_transito", "en_reparto", "entregado", "devuelto", "cancelado"];
ensure("col_shipment_tracking", {
  bsonType: "object",
  title: "Seguimiento de envíos",
  required: ["order_id", "user_id", "carrier", "tracking_number", "status", "events", "estimated_delivery", "created_at"],
  properties: {
    order_id: Object.assign({ description: "tbb_orders.id en PostgreSQL" }, pgId),
    user_id: Object.assign({ description: "tb_users.id en PostgreSQL" }, pgId),
    carrier: { enum: ["Estafeta", "DHL", "FedEx", "Paquetexpress", "Redpack"] },
    tracking_number: { bsonType: "string", pattern: "^[A-Z0-9]{10,20}$" },
    status: { enum: shipmentStatus },
    events: {
      bsonType: "array",
      minItems: 1,
      items: {
        bsonType: "object",
        required: ["status", "location", "date"],
        properties: { status: { enum: shipmentStatus }, location: text(2, 120), date: { bsonType: "date" } }
      }
    },
    estimated_delivery: { bsonType: "date" },
    delivered_at: { bsonType: ["date", "null"] },
    created_at: { bsonType: "date" },
    updated_at: { bsonType: "date" }
  }
});

ensure("col_logs", {
  bsonType: "object",
  title: "Bitácora de operaciones",
  required: ["fecha", "operacion", "usuario", "rol", "ip", "coleccion", "descripcion", "estado"],
  properties: {
    fecha: { bsonType: "date" },
    operacion: { enum: ["CREATE", "READ", "UPDATE", "DELETE", "ADMIN"] },
    usuario: { bsonType: "string" },
    rol: { bsonType: "string" },
    ip: { bsonType: "string" },
    coleccion: { bsonType: "string" },
    documento_id: { bsonType: ["objectId", "string", "null"] },
    descripcion: { bsonType: "string" },
    estado: { enum: ["exitoso", "denegado", "error"] },
    datos_anteriores: { bsonType: ["object", "null"] },
    datos_nuevos: { bsonType: ["object", "null"] },
    origen: { bsonType: "string" }
  }
});
