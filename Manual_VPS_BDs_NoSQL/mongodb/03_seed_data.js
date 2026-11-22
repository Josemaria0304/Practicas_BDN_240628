// 03_seed_data.js - Documentos de prueba con IDs reales de PostgreSQL (db_test_u2)
// Usuarios: 1 y los compradores de tbb_orders (10232, 8559, 9916, 4914, 2653)
// Productos: los comprados en tbd_order_details | Órdenes: las 5 de tbb_orders
// Ejecutar: mrun 03_seed_data.js   (solo inserta si la colección está vacía)
const d = (s) => new Date(s);
function seed(name, docs) {
  const c = db.getCollection(name);
  if (c.countDocuments() > 0) { print(name + ": ya tiene datos, se omite"); return; }
  const r = c.insertMany(docs);
  print(name + ": " + Object.keys(r.insertedIds).length + " documentos insertados");
}

// [id de tbb_orders, user_id de esa orden]
const ORDERS = [[1, 10232], [2, 8559], [3, 9916], [4, 4914], [5, 2653]];
const addr = (user_id, alias, street, ext_number, int_number, neighborhood, city, state, zip_code, phone, references, is_default, created) =>
  ({ user_id, alias, street, ext_number, int_number, neighborhood, city, state, zip_code, country: "México", phone, references, is_default, created_at: d(created) });

seed("col_users_adress", [
  addr(1, "Casa", "Av. Juárez", "120", null, "Centro", "Xicotepec de Juárez", "Puebla", "73080", "7641002030", "Frente al zócalo", true, "2026-10-23T19:20:00Z"),
  addr(10232, "Casa", "Calle 5 de Mayo", "45", null, "Barrio de San Juan", "Xicotepec de Juárez", "Puebla", "73080", "7641118899", "Portón verde", true, "2026-11-02T16:00:00Z"),
  addr(10232, "Escuela", "Av. Universidad Tecnológica", "1000", null, "Tierra Negra", "Xicotepec de Juárez", "Puebla", "73080", "7641118899", "Entregar en caseta de vigilancia", false, "2026-11-02T16:05:00Z"),
  addr(8559, "Casa", "Blvd. Felipe Ángeles", "1500", "B", "Venta Prieta", "Pachuca de Soto", "Hidalgo", "42083", "7712345678", "Junto a la farmacia", true, "2026-11-11T17:40:00Z"),
  addr(8559, "Oficina", "Av. Revolución", "300", "12", "Periodistas", "Pachuca de Soto", "Hidalgo", "42060", "7712345678", "Edificio azul, recepción", false, "2026-11-11T17:42:00Z"),
  addr(9916, "Casa", "Calle Hidalgo", "33", null, "Centro", "Huauchinango", "Puebla", "73160", "7767654321", "Casa de dos pisos color crema", true, "2026-11-11T17:45:00Z"),
  addr(9916, "Trabajo", "Av. 20 de Noviembre", "210", "4", "Centro", "Poza Rica", "Veracruz", "93260", "7821239876", "Local comercial", false, "2026-11-11T17:46:00Z"),
  addr(4914, "Casa", "Calle Morelos", "78", null, "Centro", "Tulancingo", "Hidalgo", "43600", "7751472583", "Esquina con Juárez", true, "2026-11-11T17:50:00Z"),
  addr(4914, "Familia", "Calle Allende", "12", null, "Centro", "Zacatlán", "Puebla", "73310", "7973216549", "A una cuadra del reloj floral", false, "2026-11-11T17:51:00Z"),
  addr(2653, "Departamento", "Av. Reforma", "501", "302", "Centro", "Puebla", "Puebla", "72000", "2229638527", "Edificio con caseta", true, "2026-11-11T17:55:00Z"),
  addr(2653, "Casa", "Calle Guerrero", "9", null, "Centro", "Tuxpan", "Veracruz", "92800", "7839517534", "Cerca del malecón", false, "2026-11-11T17:56:00Z")
]);

// Reseñas de productos que cada usuario compró en tbd_order_details (verified_purchase = true)
seed("col_products_reviews", [
  { product_id: 583, user_id: 10232, rating: 5, title: "Excelente olla", comment: "Calienta parejo y es fácil de limpiar.", verified_purchase: true, helpful_votes: 12, created_at: d("2026-11-14T10:00:00Z") },
  { product_id: 583, user_id: 1, rating: 4, title: "Buena calidad", comment: "Muy buena, aunque la tapa podría cerrar mejor.", verified_purchase: false, helpful_votes: 3, created_at: d("2026-11-15T09:30:00Z") },
  { product_id: 8661, user_id: 10232, rating: 3, title: "Cumple", comment: "El mouse funciona, pero la batería dura poco.", verified_purchase: true, helpful_votes: 2, created_at: d("2026-11-14T10:10:00Z") },
  { product_id: 508, user_id: 8559, rating: 5, title: "Ideal para la escuela", comment: "Tiene todas las funciones que pide el profesor.", verified_purchase: true, helpful_votes: 8, created_at: d("2026-11-16T18:20:00Z") },
  { product_id: 4800, user_id: 8559, rating: 2, title: "No era lo que esperaba", comment: "El sofá es más pequeño de lo que se ve en la foto.", verified_purchase: true, helpful_votes: 15, created_at: d("2026-11-16T18:25:00Z") },
  { product_id: 13575, user_id: 8559, rating: 4, title: "Buen monitor", comment: "Buena imagen por el precio, el soporte se mueve un poco.", verified_purchase: true, helpful_votes: 6, created_at: d("2026-11-16T18:30:00Z") },
  { product_id: 11163, user_id: 9916, rating: 5, title: "Perfecto", comment: "Hojas gruesas y buen tamaño para apuntes.", verified_purchase: true, helpful_votes: 4, created_at: d("2026-11-15T12:00:00Z") },
  { product_id: 16287, user_id: 9916, rating: 4, title: "Muy útil", comment: "Los lápices vienen bien afilados y completos.", verified_purchase: true, helpful_votes: 1, created_at: d("2026-11-15T12:05:00Z") },
  { product_id: 3307, user_id: 4914, rating: 1, title: "Llegó dañada", comment: "La plancha llegó con la base rayada. Pedí devolución.", verified_purchase: true, helpful_votes: 20, created_at: d("2026-11-17T11:35:00Z") },
  { product_id: 17426, user_id: 2653, rating: 3, title: "Regular", comment: "Cancelé el pedido, pero lo vi en tienda y es ruidoso.", verified_purchase: false, helpful_votes: 0, created_at: d("2026-11-18T21:15:00Z") }
]);

// Envíos: cada orden de tbb_orders puede salir en varios paquetes
const ev = (status, location, date) => ({ status, location, date: d(date) });
const o = (i) => ({ order_id: ORDERS[i][0], user_id: ORDERS[i][1] });
seed("col_shipment_tracking", [
  { ...o(0), package: "1 de 2", products: [583, 2386], carrier: "Estafeta", tracking_number: "EST7012345678MX", status: "creado", events: [ev("creado", "CDMX", "2026-11-19T09:00:00Z")], estimated_delivery: d("2026-11-28T23:59:00Z"), delivered_at: null, created_at: d("2026-11-19T09:00:00Z"), updated_at: d("2026-11-19T09:00:00Z") },
  { ...o(0), package: "2 de 2", products: [8661, 8892, 17685], carrier: "Estafeta", tracking_number: "EST7012345679MX", status: "creado", events: [ev("creado", "CDMX", "2026-11-19T09:05:00Z")], estimated_delivery: d("2026-11-29T23:59:00Z"), delivered_at: null, created_at: d("2026-11-19T09:05:00Z"), updated_at: d("2026-11-19T09:05:00Z") },
  { ...o(1), package: "1 de 3", products: [508, 1340, 4905], carrier: "DHL", tracking_number: "DHL4455667788", status: "en_transito", events: [ev("creado", "Querétaro", "2026-11-12T10:00:00Z"), ev("en_transito", "Pachuca", "2026-11-13T12:00:00Z")], estimated_delivery: d("2026-11-16T23:59:00Z"), delivered_at: null, created_at: d("2026-11-12T10:00:00Z"), updated_at: d("2026-11-13T12:00:00Z") },
  { ...o(1), package: "2 de 3", products: [4800], carrier: "Paquetexpress", tracking_number: "PQX20261112002", status: "en_transito", events: [ev("creado", "Guadalajara", "2026-11-12T11:00:00Z"), ev("en_transito", "CDMX", "2026-11-14T08:00:00Z")], estimated_delivery: d("2026-11-18T23:59:00Z"), delivered_at: null, created_at: d("2026-11-12T11:00:00Z"), updated_at: d("2026-11-14T08:00:00Z") },
  { ...o(1), package: "3 de 3", products: [10122, 12759, 13575, 15364, 16874, 18147], carrier: "DHL", tracking_number: "DHL4455667799", status: "en_reparto", events: [ev("creado", "Querétaro", "2026-11-12T10:30:00Z"), ev("en_transito", "Pachuca", "2026-11-13T12:30:00Z"), ev("en_reparto", "Pachuca de Soto", "2026-11-21T08:00:00Z")], estimated_delivery: d("2026-11-22T23:59:00Z"), delivered_at: null, created_at: d("2026-11-12T10:30:00Z"), updated_at: d("2026-11-21T08:00:00Z") },
  { ...o(2), package: "1 de 2", products: [11163], carrier: "FedEx", tracking_number: "FDX998877665544", status: "entregado", events: [ev("creado", "Monterrey", "2026-11-11T18:00:00Z"), ev("en_transito", "San Luis Potosí", "2026-11-12T22:00:00Z"), ev("en_reparto", "Huauchinango", "2026-11-14T08:30:00Z"), ev("entregado", "Huauchinango", "2026-11-14T13:10:00Z")], estimated_delivery: d("2026-11-15T23:59:00Z"), delivered_at: d("2026-11-14T13:10:00Z"), created_at: d("2026-11-11T18:00:00Z"), updated_at: d("2026-11-14T13:10:00Z") },
  { ...o(2), package: "2 de 2", products: [16287], carrier: "FedEx", tracking_number: "FDX998877665545", status: "entregado", events: [ev("creado", "Monterrey", "2026-11-11T18:10:00Z"), ev("en_transito", "San Luis Potosí", "2026-11-12T22:10:00Z"), ev("entregado", "Huauchinango", "2026-11-15T11:00:00Z")], estimated_delivery: d("2026-11-15T23:59:00Z"), delivered_at: d("2026-11-15T11:00:00Z"), created_at: d("2026-11-11T18:10:00Z"), updated_at: d("2026-11-15T11:00:00Z") },
  { ...o(3), package: "1 de 2", products: [3307], carrier: "Redpack", tracking_number: "RPK5544332211", status: "devuelto", events: [ev("creado", "CDMX", "2026-11-11T19:00:00Z"), ev("en_transito", "Tulancingo", "2026-11-12T16:30:00Z"), ev("entregado", "Tulancingo", "2026-11-13T12:00:00Z"), ev("devuelto", "Tulancingo", "2026-11-17T10:00:00Z")], estimated_delivery: d("2026-11-14T23:59:00Z"), delivered_at: d("2026-11-13T12:00:00Z"), created_at: d("2026-11-11T19:00:00Z"), updated_at: d("2026-11-17T10:00:00Z") },
  { ...o(3), package: "2 de 2", products: [3592, 8378], carrier: "Redpack", tracking_number: "RPK5544332212", status: "entregado", events: [ev("creado", "CDMX", "2026-11-11T19:10:00Z"), ev("en_transito", "Tulancingo", "2026-11-12T16:40:00Z"), ev("entregado", "Tulancingo", "2026-11-13T12:20:00Z")], estimated_delivery: d("2026-11-14T23:59:00Z"), delivered_at: d("2026-11-13T12:20:00Z"), created_at: d("2026-11-11T19:10:00Z"), updated_at: d("2026-11-13T12:20:00Z") },
  { ...o(4), package: "1 de 1", products: [17426], carrier: "Estafeta", tracking_number: "EST7098765432MX", status: "cancelado", events: [ev("creado", "Puebla", "2026-11-11T20:00:00Z"), ev("cancelado", "Puebla", "2026-11-12T09:00:00Z")], estimated_delivery: d("2026-11-16T23:59:00Z"), delivered_at: null, created_at: d("2026-11-11T20:00:00Z"), updated_at: d("2026-11-12T09:00:00Z") }
]);
