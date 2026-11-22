// 01_users_roles.js - Los 7 roles del e-commerce (mismos nombres que en MySQL y PostgreSQL),
// una cuenta de prueba por rol y los usuarios del equipo
// Ejecutar: mrun 01_users_roles.js   (se puede repetir: crea o actualiza)
// Antes de subirlo a GitHub, reemplaza las contraseñas del equipo por "CAMBIAR".
const DB = db.getName();
const PASS = process.env.TEST_USERS_PASSWORD;
const A = "col_users_adress", R = "col_products_reviews", S = "col_shipment_tracking";
const on = (c) => ({ db: DB, collection: c });   // una colección o vista
const ALL = { db: DB, collection: "" };            // todas las colecciones de la base

// ---------- Roles ----------
const roles = {
  superadmin: { privileges: [], roles: [{ role: "dbOwner", db: DB }] },   // todo, incluidos usuarios y roles
  admin: { privileges: [
    { resource: ALL, actions: ["find", "insert", "update", "remove", "createCollection",
      "createIndex", "dropIndex", "collMod", "listCollections", "listIndexes", "viewUser", "viewRole"] }
  ], roles: [] },
  seller: { privileges: [
    { resource: on(R), actions: ["find"] },
    { resource: on(S), actions: ["find", "update"] },
    { resource: on("vw_product_rating_summary"), actions: ["find"] }
  ], roles: [] },
  buyer: { privileges: [
    { resource: on(A), actions: ["find", "insert", "update", "remove"] },
    { resource: on(R), actions: ["find", "insert", "update"] },
    { resource: on(S), actions: ["find"] }
  ], roles: [] },
  support: { privileges: [
    { resource: on(A), actions: ["find"] },
    { resource: on(R), actions: ["find"] },
    { resource: on(S), actions: ["find", "update"] },
    { resource: on("vw_shipments_active"), actions: ["find"] },
    { resource: on("vw_shipments_delayed"), actions: ["find"] }
  ], roles: [] },
  common_user: { privileges: [
    { resource: on(R), actions: ["find"] },
    { resource: on("vw_public_reviews"), actions: ["find"] },
    { resource: on("vw_product_rating_summary"), actions: ["find"] }
  ], roles: [] },
  user_not_registered: { privileges: [
    { resource: on("vw_public_reviews"), actions: ["find"] },
    { resource: on("vw_product_rating_summary"), actions: ["find"] }
  ], roles: [] }
};

for (const [name, def] of Object.entries(roles)) {
  if (db.getRole(name)) { db.updateRole(name, def); print("Rol actualizado: " + name); }
  else { db.createRole(Object.assign({ role: name }, def)); print("Rol creado: " + name); }
}

// Limpieza de los nombres anteriores (r_*, u_common, u_not_registered), si existen
["u_common", "u_not_registered"].forEach((u) => { if (db.getUser(u)) { db.dropUser(u); print("Cuenta anterior eliminada: " + u); } });
["r_admin", "r_seller", "r_buyer", "r_support", "r_common", "r_not_registered"].forEach((r) => {
  if (db.getRole(r)) { db.dropRole(r); print("Rol anterior eliminado: " + r); }
});

function upsertUser(user, pwd, userRoles) {
  const rs = userRoles.map((r) => ({ role: r, db: DB }));
  if (db.getUser(user)) db.updateUser(user, { pwd, roles: rs });
  else db.createUser({ user, pwd, roles: rs });
  print("Cuenta " + user + " -> " + (userRoles.join(", ") || "sin rol"));
}

// ---------- Una cuenta de prueba por rol (para 06_tests_crud.js) ----------
if (!PASS) {
  print("TEST_USERS_PASSWORD no definida: no se crean las cuentas de prueba");
} else {
  Object.keys(roles).forEach((r) => upsertUser("u_" + r, PASS + "_" + r, [r]));
}

// ---------- Usuarios del equipo (los mismos de MySQL y PostgreSQL) ----------
const team = [
  ["jose.castillo", "240628", ["superadmin"]],
  ["marco.ramirez", "qwerty123", ["admin"]],
  ["fernando.miguel", "240161", ["support"]],
  ["carlos.cabrera", "240201", []],
  ["yuliana.mendoza", "240808", ["seller"]],
  ["adrian.gomez", "240165", ["seller"]],
  ["hector.morales", "240763", []],
  ["app.web", "web123", ["user_not_registered", "common_user", "buyer"]],
  ["app.movil", "mobile890", ["user_not_registered"]]
];
team.forEach(([u, p, rs]) => upsertUser(u, p, rs));

// ---------- Usuario técnico de la API GraphQL (rol integrado readWrite) ----------
const APP = process.env.MONGO_APP_USER;
if (APP && !db.getUser(APP)) {
  db.createUser({ user: APP, pwd: process.env.MONGO_APP_PASSWORD, roles: [{ role: "readWrite", db: DB }] });
}
print("Usuario de la API GraphQL creado en " + DB);
