// 04_indexes.js - Índices para las consultas principales
// Ejecutar: mrun 04_indexes.js   (se puede repetir)
const idx = (coll, keys, opts) => { db.getCollection(coll).createIndex(keys, opts); print(coll + " -> " + opts.name); };

// Reseñas de un producto ordenadas por calificación (API reviews, vista de resumen)
idx("col_products_reviews", { product_id: 1, rating: -1 }, { name: "ix_reviews_product_rating" });
// Un usuario solo puede reseñar una vez cada producto
idx("col_products_reviews", { user_id: 1, product_id: 1 }, { name: "ux_reviews_user_product", unique: true });

// Direcciones de un usuario, primero la predeterminada
idx("col_users_adress", { user_id: 1, is_default: -1 }, { name: "ix_address_user_default" });

// Buscar un envío por su número de guía (único)
idx("col_shipment_tracking", { tracking_number: 1 }, { name: "ux_shipment_tracking_number", unique: true });
// Envíos por estado y fecha estimada (vistas de activos y retrasados)
idx("col_shipment_tracking", { status: 1, estimated_delivery: 1 }, { name: "ix_shipment_status_eta" });
// Envíos de una orden de PostgreSQL
idx("col_shipment_tracking", { order_id: 1 }, { name: "ix_shipment_order" });

// Bitácora: lo más reciente primero, y filtrada por usuario o estado
idx("col_logs", { fecha: -1 }, { name: "ix_logs_fecha" });
idx("col_logs", { usuario: 1, fecha: -1 }, { name: "ix_logs_usuario_fecha" });
idx("col_logs", { estado: 1, fecha: -1 }, { name: "ix_logs_estado_fecha" });

// Demostración de consulta optimizada (indicador 42)
const plan = db.col_products_reviews.find({ product_id: 583, rating: { $gte: 4 } }).sort({ rating: -1 }).explain("executionStats");
const stage = (s) => (s.inputStage ? stage(s.inputStage) : s.stage + (s.indexName ? " (" + s.indexName + ")" : ""));
print("Consulta: reseñas del producto 583 con 4 o más estrellas");
const wp = plan.queryPlanner.winningPlan;
print("  Etapa de lectura: " + stage(wp.queryPlan || wp));
print("  Documentos devueltos: " + plan.executionStats.nReturned + ", documentos revisados: " + plan.executionStats.totalDocsExamined + ", llaves revisadas: " + plan.executionStats.totalKeysExamined);
