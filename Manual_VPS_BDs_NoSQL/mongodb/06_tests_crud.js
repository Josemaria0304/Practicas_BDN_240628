// 06_tests_crud.js - Casos de prueba CRUD por rol, con registro real en col_logs
// En el VPS:        RUN_TESTS=1 mrun 06_tests_crud.js
// Desde una PC:     ver la guía (variables MONGO_HOST, MONGO_PORT, TEST_USERS_PASSWORD, RUN_TESTS)
(function () {
  if (process.env.RUN_TESTS !== "1") { print("06_tests_crud.js omitido: define RUN_TESTS=1 para ejecutarlo"); return; }

  const DB = db.getName();
  const HOST = process.env.MONGO_HOST || "localhost";
  const PORT = process.env.MONGO_PORT || "27017";
  const PASS = process.env.TEST_USERS_PASSWORD;
  if (!PASS) { print("Falta TEST_USERS_PASSWORD"); return; }
  const A = "col_users_adress", R = "col_products_reviews", S = "col_shipment_tracking";
  const logs = db.getCollection("col_logs");   // se escribe con la conexión que ejecuta el script

  let ip = "desconocida";
  try { ip = db.adminCommand({ whatsmyuri: 1 }).you.replace(/:\d+$/, ""); } catch (e) { /* sin IP */ }

  // Conexión independiente para cada cuenta de prueba: MongoDB aplica sus privilegios
  const conns = {};
  function as(role) {
    if (!conns[role]) {
      const uri = "mongodb://u_" + role + ":" + encodeURIComponent(PASS + "_" + role) + "@" + HOST + ":" + PORT + "/" + DB + "?authSource=" + DB;
      conns[role] = new Mongo(uri).getDB(DB);
    }
    return conns[role];
  }
  const roleName = (r) => r;   // la cuenta u_<rol> tiene el rol del mismo nombre
  const isDenied = (e) => e.code === 13 || /not authorized|unauthorized/i.test(String(e.message));

  function audit(role, op, coll, docId, desc, estado, antes, despues) {
    logs.insertOne({
      fecha: new Date(), operacion: op, usuario: "u_" + role, rol: roleName(role), ip: ip,
      coleccion: coll, documento_id: docId || null, descripcion: desc, estado: estado,
      datos_anteriores: antes || null, datos_nuevos: despues || null, origen: "mongosh 06_tests_crud.js"
    });
  }

  let pass = 0, fail = 0;
  function test(n, role, op, coll, desc, expected, fn) {
    print("\n[" + n + "] " + role + " | " + op + " | " + coll + " | " + desc + " | esperado: " + expected);
    try {
      const r = fn(as(role)) || {};
      audit(role, op, coll, r.id, desc, "exitoso", r.antes, r.despues);
      if (expected === "permitido") { pass++; print("    OK: permitido"); } else { fail++; print("    FALLA: se esperaba denegado"); }
      return r;
    } catch (e) {
      if (!isDenied(e)) { fail++; audit(role, op, coll, null, desc + ": " + e.message, "error"); print("    ERROR: " + e.message); return null; }
      audit(role, op, coll, null, desc + " (sin privilegios)", "denegado");
      if (expected === "denegado") { pass++; print("    OK: denegado -> " + e.message); } else { fail++; print("    FALLA: denegado -> " + e.message); }
      return null;
    }
  }

  // Limpieza: quita la reseña de prueba si quedó de una ejecución anterior
  db.getCollection(R).deleteMany({ user_id: 1, product_id: 1 });

  print("=============== CRUD PERMITIDO ===============");
  const created = test(1, "buyer", "CREATE", R, "buyer publica una reseña del producto 1", "permitido", (d) => {
    const id = d.getCollection(R).insertOne({ product_id: 1, user_id: 1, rating: 4, title: "Buena calidad",
      comment: "Llegó rápido y bien empacado.", verified_purchase: true, created_at: new Date() }).insertedId;
    const persisted = d.getCollection(R).findOne({ _id: id });
    print("    Documento persistido:"); printjson(persisted);
    return { id: id, despues: persisted };
  });

  test(2, "common_user", "READ", R, "common_user consulta reseñas del producto 583 con 4+ estrellas (filtro y proyección)", "permitido", (d) => {
    const docs = d.getCollection(R).find({ product_id: 583, rating: { $gte: 4 } }, { _id: 0, product_id: 1, rating: 1, title: 1 }).sort({ rating: -1 }).toArray();
    printjson(docs);
    return {};
  });

  if (created) {
    test(3, "buyer", "UPDATE", R, "buyer cambia la calificación de su reseña a 5", "permitido", (d) => {
      const antes = d.getCollection(R).findOne({ _id: created.id });
      d.getCollection(R).updateOne({ _id: created.id }, { $set: { rating: 5, comment: "Después de una semana de uso sigue perfecto." } });
      const despues = d.getCollection(R).findOne({ _id: created.id });
      print("    Antes:"); printjson(antes); print("    Después:"); printjson(despues);
      return { id: created.id, antes: antes, despues: despues };
    });

    test(4, "admin", "DELETE", R, "admin elimina la reseña de prueba", "permitido", (d) => {
      const antes = d.getCollection(R).findOne({ _id: created.id });
      d.getCollection(R).deleteOne({ _id: created.id });
      print("    ¿Sigue disponible?: " + (d.getCollection(R).findOne({ _id: created.id }) !== null));
      return { id: created.id, antes: antes };
    });
  }

  print("\n=============== PRIVILEGIOS POR ROL ===============");
  test(5, "superadmin", "ADMIN", "usuarios", "superadmin crea y elimina una cuenta temporal", "permitido", (d) => {
    d.createUser({ user: "u_temporal", pwd: "Temporal_" + Date.now(), roles: [{ role: "common_user", db: DB }] });
    print("    Cuentas en la base: " + d.getUsers().users.map((u) => u.user).join(", "));
    d.dropUser("u_temporal");
    return {};
  });

  test(6, "admin", "ADMIN", R, "admin crea y elimina un índice temporal", "permitido", (d) => {
    d.getCollection(R).createIndex({ helpful_votes: -1 }, { name: "ix_temporal" });
    print("    Índices: " + d.getCollection(R).getIndexes().map((i) => i.name).join(", "));
    d.getCollection(R).dropIndex("ix_temporal");
    return {};
  });

  test(7, "admin", "ADMIN", "usuarios", "admin intenta crear una cuenta", "denegado", (d) => {
    d.createUser({ user: "u_no_permitido", pwd: "x_" + Date.now(), roles: [] });
  });

  test(8, "seller", "UPDATE", S, "seller marca el primer paquete de la orden 1 como en tránsito", "permitido", (d) => {
    const antes = d.getCollection(S).findOne({ order_id: 1 });
    d.getCollection(S).updateOne({ order_id: 1 }, { $set: { status: "en_transito", updated_at: new Date() },
      $push: { events: { status: "en_transito", location: "Puebla", date: new Date() } } });
    const despues = d.getCollection(S).findOne({ order_id: 1 });
    return { id: despues._id, antes: antes, despues: despues };
  });

  test(9, "seller", "CREATE", A, "seller intenta registrar una dirección", "denegado", (d) => {
    d.getCollection(A).insertOne({ user_id: 2, alias: "Prueba", street: "Calle X", ext_number: "1", neighborhood: "Centro",
      city: "Puebla", state: "Puebla", zip_code: "72000", country: "México", is_default: false, created_at: new Date() });
  });

  test(10, "buyer", "DELETE", S, "buyer intenta borrar un envío", "denegado", (d) => {
    d.getCollection(S).deleteOne({ order_id: 5 });
  });

  test(11, "support", "UPDATE", S, "support registra un evento en un paquete de la orden 2", "permitido", (d) => {
    const antes = d.getCollection(S).findOne({ order_id: 2 });
    d.getCollection(S).updateOne({ order_id: 2 }, { $set: { status: "en_reparto", updated_at: new Date() },
      $push: { events: { status: "en_reparto", location: "Pachuca de Soto", date: new Date() } } });
    const despues = d.getCollection(S).findOne({ order_id: 2 });
    return { id: despues._id, antes: antes, despues: despues };
  });

  test(12, "support", "READ", "vw_shipments_delayed", "support consulta envíos retrasados", "permitido", (d) => {
    printjson(d.getCollection("vw_shipments_delayed").find().toArray());
    return {};
  });

  test(13, "support", "DELETE", A, "support intenta borrar una dirección", "denegado", (d) => {
    d.getCollection(A).deleteOne({ user_id: 1 });
  });

  test(14, "common_user", "CREATE", R, "common_user intenta publicar una reseña", "denegado", (d) => {
    d.getCollection(R).insertOne({ product_id: 2, user_id: 2, rating: 5, comment: "Prueba sin permiso", created_at: new Date() });
  });

  test(15, "user_not_registered", "READ", "vw_public_reviews", "user_not_registered consulta reseñas públicas", "permitido", (d) => {
    printjson(d.getCollection("vw_public_reviews").find({}, { _id: 0, product_id: 1, rating: 1, title: 1 }).limit(3).toArray());
    return {};
  });

  test(16, "user_not_registered", "READ", R, "user_not_registered intenta leer la colección con user_id", "denegado", (d) => {
    d.getCollection(R).findOne();
  });

  test(17, "user_not_registered", "UPDATE", R, "user_not_registered intenta modificar una reseña", "denegado", (d) => {
    d.getCollection(R).updateOne({ product_id: 1 }, { $set: { rating: 1 } });
  });

  print("\n=============== RESUMEN ===============");
  print("Casos con el resultado esperado: " + pass + " de " + (pass + fail));
  print("Registros de esta ejecución en col_logs:");
  printjson(logs.find({ origen: "mongosh 06_tests_crud.js" }, { _id: 0, fecha: 1, usuario: 1, operacion: 1, coleccion: 1, estado: 1, ip: 1 })
    .sort({ fecha: -1 }).limit(17).toArray());
})();
