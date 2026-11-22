// 05_views.js - Vistas de MongoDB
// Ejecutar: mrun 05_views.js   (se puede repetir: borra y vuelve a crear cada vista)
function view(name, source, pipeline) {
  if (db.getCollectionNames().includes(name)) db.getCollection(name).drop();
  db.createView(name, source, pipeline);
  print("Vista creada: " + name + " (" + db.getCollection(name).countDocuments() + " documentos)");
}

// 1. Reseñas públicas, sin el ID del usuario (para user_not_registered y common_user)
view("vw_public_reviews", "col_products_reviews", [
  { $project: { product_id: 1, rating: 1, title: 1, comment: 1, verified_purchase: 1, created_at: 1 } },
  { $sort: { created_at: -1 } }
]);

// 2. Calificación promedio y total de reseñas por producto
view("vw_product_rating_summary", "col_products_reviews", [
  { $group: { _id: "$product_id", promedio: { $avg: "$rating" }, total: { $sum: 1 } } },
  { $project: { _id: 0, product_id: "$_id", promedio: { $round: ["$promedio", 2] }, total: 1 } },
  { $sort: { promedio: -1, total: -1 } }
]);

// 3. Envíos en curso con su último evento (para support)
view("vw_shipments_active", "col_shipment_tracking", [
  { $match: { status: { $in: ["creado", "en_transito", "en_reparto"] } } },
  { $project: { order_id: 1, user_id: 1, carrier: 1, tracking_number: 1, status: 1, estimated_delivery: 1, ultimo_evento: { $last: "$events" } } },
  { $sort: { estimated_delivery: 1 } }
]);

// 4. Envíos retrasados: no entregados y con fecha estimada ya vencida
view("vw_shipments_delayed", "col_shipment_tracking", [
  { $match: { status: { $in: ["creado", "en_transito", "en_reparto"] }, $expr: { $lt: ["$estimated_delivery", "$$NOW"] } } },
  { $project: { order_id: 1, user_id: 1, carrier: 1, tracking_number: 1, status: 1, estimated_delivery: 1,
      dias_retraso: { $dateDiff: { startDate: "$estimated_delivery", endDate: "$$NOW", unit: "day" } } } },
  { $sort: { dias_retraso: -1 } }
]);

// 5. Dirección predeterminada de cada usuario en una sola línea
view("vw_users_default_address", "col_users_adress", [
  { $match: { is_default: true } },
  { $project: { _id: 0, user_id: 1, city: 1, state: 1, zip_code: 1,
      direccion: { $concat: ["$street", " ", "$ext_number", ", ", "$neighborhood", ", ", "$city", ", ", "$state"] } } }
]);

// 6. Intentos denegados registrados en la bitácora (para superadmin y admin)
view("vw_logs_denied", "col_logs", [
  { $match: { estado: "denegado" } },
  { $project: { _id: 0, fecha: 1, usuario: 1, rol: 1, ip: 1, operacion: 1, coleccion: 1, descripcion: 1 } },
  { $sort: { fecha: -1 } }
]);
