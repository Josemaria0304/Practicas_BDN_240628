# Unidad 2 · Bases de Datos NoSQL en la Nube

**Optativa I: Bases de Datos en la Nube · 7A ITIID · UTXJ**
Alumno: José Castillo · Matrícula 240628 · VPS `srv2060502.hstgr.cloud` (Hostinger)

Un solo proyecto Docker Compose (`nosql_240628`) con 5 servicios: PostgreSQL y pgAdmin (conservados de la Unidad 1), MongoDB 8, Mongo Express y una API GraphQL propia. La base relacional del e-commerce (`db_test`) está en MySQL y migrada a PostgreSQL (`db_test_u2`). MongoDB (`db_ecommerce_nosql`) guarda direcciones, reseñas, seguimiento de envíos y la bitácora, enlazados por ID con PostgreSQL.

> Las credenciales de acceso para evaluación están en [`ACCESO_PROFESOR.md`](ACCESO_PROFESOR.md), que se entrega aparte y **no** se sube al repositorio.

---

## Servicios

| Servicio | Contenedor | Imagen | Puerto | Acceso |
| --- | --- | --- | --- | --- |
| PostgreSQL | `pg_240628` | postgres:18 | 40631 | `srv2060502.hstgr.cloud:40631` |
| pgAdmin Web | `pgadmin_240628` | dpage/pgadmin4 | 40632 | http://srv2060502.hstgr.cloud:40632 |
| MongoDB | `u2_mongo_240628` | mongo:8.0 (`--auth`) | 40633 | `srv2060502.hstgr.cloud:40633` |
| Mongo Express | `u2_mongoexpress_240628` | mongo-express:1.0.2 | 40634 | http://srv2060502.hstgr.cloud:40634 |
| API GraphQL | `u2_graphql_240628` | Node 22 + Apollo Server | 40635 | http://srv2060502.hstgr.cloud:40635 |
| MySQL (Unidad 1) | `mysql_240628` | mysql:8.4 | 40629 | `srv2060502.hstgr.cloud:40629` (fuera de este stack) |

| Base | Motor | Contenido |
| --- | --- | --- |
| `db_test_u2` | PostgreSQL | E-commerce migrado desde MySQL: 25 tablas, 10,229 usuarios, 15,007 productos, 5 órdenes |
| `db_test` | MySQL | La misma base, completa con vistas, triggers y procedimientos |
| `db_ecommerce_nosql` | MongoDB | 4 colecciones con JSON Schema y 6 vistas |

---

## Estructura

```
Manual_VPS_BDs_NoSQL/
├── docker-compose.yml            # 5 servicios, red y volúmenes
├── .env.example                  # variables sin secretos (copiar a .env)
├── .gitignore                    # excluye .env y node_modules
├── mongodb/
│   ├── 01_users_roles.js         # 7 roles, cuentas de prueba y usuarios del equipo
│   ├── 02_collections_schemas.js # colecciones con validación JSON Schema
│   ├── 03_seed_data.js           # datos de prueba con IDs reales de PostgreSQL
│   ├── 04_indexes.js             # índices y consulta optimizada (explain)
│   ├── 05_views.js               # 6 vistas
│   └── 06_tests_crud.js          # 17 pruebas CRUD por rol con registro en col_logs
├── postgres/
│   └── roles_usuarios_postgresql.sql  # mismos roles y usuarios en PostgreSQL
└── graphql/
    ├── Dockerfile
    ├── package.json
    └── src/index.js              # API con trazabilidad en col_logs
```

---

## Cómo levantarlo

```bash
cp .env.example .env              # y poner contraseñas reales
docker compose up -d --build
docker compose ps                 # los 5 contenedores en Up
```

En el primer arranque, MongoDB ejecuta solo los scripts 01 a 05. Las pruebas se ejecutan aparte:

```bash
set -a; source .env; set +a
docker exec -e RUN_TESTS=1 u2_mongo_240628 mongosh -u "$MONGO_ROOT_USER" -p "$MONGO_ROOT_PASSWORD" \
  --authenticationDatabase admin "$MONGO_DB" --file /docker-entrypoint-initdb.d/06_tests_crud.js
```

---

## Roles (iguales en MySQL, PostgreSQL y MongoDB)

| Rol | Puede |
| --- | --- |
| `superadmin` | Todo, incluido crear usuarios y roles |
| `admin` | Leer y modificar todos los datos, crear índices; no crea usuarios |
| `seller` | Gestionar productos (SQL); actualizar envíos y ver el ranking de productos (NoSQL) |
| `buyer` | Lista de deseos (SQL); direcciones, reseñas propias y consulta de envíos (NoSQL) |
| `support` | Atender usuarios y catálogo (SQL); actualizar envíos y ver retrasados (NoSQL) |
| `common_user` | Consultar productos y reseñas |
| `user_not_registered` | Registrarse (SQL) y ver solo vistas públicas (NoSQL) |

| Usuario | Rol |
| --- | --- |
| `jose.castillo` | superadmin |
| `marco.ramirez` (profesor) | admin |
| `fernando.miguel` | support |
| `adrian.gomez`, `yuliana.mendoza` | seller |
| `app.web` | user_not_registered, common_user, buyer |
| `app.movil` | user_not_registered |
| `carlos.cabrera`, `hector.morales` | sin rol |

---

## MongoDB

| Colección | Contenido | Relación con PostgreSQL |
| --- | --- | --- |
| `col_users_adress` | 11 direcciones | `user_id` → `tb_users.id` |
| `col_products_reviews` | 10 reseñas | `product_id` → `tb_products.id`, `user_id` → `tb_users.id` |
| `col_shipment_tracking` | 10 envíos | `order_id` → `tbb_orders.id` |
| `col_logs` | Bitácora de operaciones | — |

Vistas: `vw_public_reviews`, `vw_product_rating_summary`, `vw_shipments_active`, `vw_shipments_delayed`, `vw_users_default_address`, `vw_logs_denied`.

**Trazabilidad:** MongoDB sin Atlas no tiene triggers, así que la API GraphQL y el script de pruebas registran cada operación en `col_logs` con fecha, operación, usuario, rol, IP, colección, documento, estado y datos anteriores y nuevos.

---

## API GraphQL

La API no tiene login: cada petición lleva la cuenta de MongoDB en los encabezados `x-db-user` y `x-db-pass`, y MongoDB aplica los permisos de ese rol.

| Tipo | Operación |
| --- | --- |
| Query | `whoami`, `reviews`, `publicReviews`, `productRatings`, `shipments`, `logs` |
| Mutation | `createReview`, `updateReview`, `deleteReview`, `updateShipmentStatus` |

```graphql
query {
  whoami
  productRatings(minPromedio: 4, limit: 5) { product_id promedio total }
}
```

---

## Seguridad

- MongoDB arranca con `--auth`; Mongo Express exige usuario y contraseña.
- Cada usuario tiene solo los privilegios de su rol, en los tres motores.
- El `.env` real tiene permisos 600 y está en `.gitignore`; el repositorio solo incluye `.env.example`.
- Las contraseñas del equipo en los scripts se reemplazan por `CAMBIAR` antes de subirlos.
