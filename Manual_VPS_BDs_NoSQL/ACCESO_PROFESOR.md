# Acceso para evaluación · Unidad 2 · Matrícula 240628

**Profesor:** Marco Ramírez · usuario `marco.ramirez` · rol **admin** en los tres motores
**Servidor:** `srv2060502.hstgr.cloud`

> Documento confidencial para evaluación. No subir a GitHub ni compartir.

Con el rol admin puede leer y modificar todos los datos y crear índices, pero no crear usuarios ni roles.

---

## Resumen

| Servicio | Dirección | Usuario | Contraseña |
| --- | --- | --- | --- |
| PostgreSQL (`db_test_u2`) | `srv2060502.hstgr.cloud:40631` | `marco.ramirez` | `qwerty123` |
| pgAdmin Web (login de la página) | http://srv2060502.hstgr.cloud:40632 | `marco.ramirez@utxicotepec.edu.mx` | `qwerty123` |
| MongoDB (`db_ecommerce_nosql`) | `srv2060502.hstgr.cloud:40633` | `marco.ramirez` | `qwerty123` |
| Mongo Express | http://srv2060502.hstgr.cloud:40634 | `Admin` | `12345` |
| API GraphQL | http://srv2060502.hstgr.cloud:40635 | `marco.ramirez` (encabezado) | `qwerty123` (encabezado) |
| MySQL (`db_test`) | `srv2060502.hstgr.cloud:40629` | `marco.ramirez` | `qwerty123` |

---

## 1. PostgreSQL

**pgAdmin de escritorio (en su PC):** Servers → Register → Server.

| Pestaña | Campo | Valor |
| --- | --- | --- |
| General | Name | `VPS 240628 · db_test_u2` |
| Connection | Host name/address | `srv2060502.hstgr.cloud` |
| Connection | Port | `40631` |
| Connection | Maintenance database | `db_test_u2` |
| Connection | Username | `marco.ramirez` |
| Connection | Password | `qwerty123` |

**Terminal:**

```bash
psql -h srv2060502.hstgr.cloud -p 40631 -U marco.ramirez -d db_test_u2
```

## 2. pgAdmin Web

1. Abrir http://srv2060502.hstgr.cloud:40632 e iniciar sesión con la cuenta de pgAdmin de la tabla.
2. Servers → Register → Server, con estos datos (conexión interna de Docker):

| Campo | Valor |
| --- | --- |
| Host name/address | `postgres` |
| Port | `5432` |
| Maintenance database | `db_test_u2` |
| Username | `marco.ramirez` |
| Password | `qwerty123` |

## 3. MongoDB

**mongosh o MongoDB Compass**, con esta cadena de conexión:

```
mongodb://marco.ramirez:qwerty123@srv2060502.hstgr.cloud:40633/db_ecommerce_nosql?authSource=db_ecommerce_nosql
```

Consultas de ejemplo:

```javascript
db.getCollectionNames()
db.vw_product_rating_summary.find()
db.col_logs.find().sort({ fecha: -1 }).limit(5)
db.vw_logs_denied.find().limit(5)
```

## 4. Mongo Express

Abrir http://srv2060502.hstgr.cloud:40634 con el usuario y la contraseña de la tabla, y entrar a la base `db_ecommerce_nosql`. Mongo Express usa una sola cuenta general, no los usuarios de MongoDB.

## 5. API GraphQL

1. Abrir http://srv2060502.hstgr.cloud:40635 (Apollo Sandbox).
2. Clic en el engrane ⚙ junto a la dirección → **Connection settings**.
3. En **Shared headers**, agregar:

| header key | value |
| --- | --- |
| `x-db-user` | `marco.ramirez` |
| `x-db-pass` | `qwerty123` |

4. Apagar **Include cookies** y clic en **Save**.
5. Ejecutar:

```graphql
query { whoami }
```

Respuesta esperada: `"marco.ramirez (admin) desde <su IP>"`.

```graphql
query {
  reviews(product_id: 583, minRating: 4, limit: 5) { id rating title }
  productRatings(minPromedio: 4, limit: 5) { product_id promedio total }
  logs(limit: 10) { fecha usuario rol ip operacion coleccion estado descripcion }
}
```

## 6. MySQL

MySQL Workbench → nueva conexión:

| Campo | Valor |
| --- | --- |
| Hostname | `srv2060502.hstgr.cloud` |
| Port | `40629` |
| Username | `marco.ramirez` |
| Password | `qwerty123` |
| Default Schema | `db_test` |

---

## Cuentas de prueba por rol (MongoDB y API)

Para comprobar permisos de otros roles. Contraseña = base + `_` + rol (por ejemplo `u_seller` usa `<base>_seller`).

| Cuenta | Rol | Contraseña |
| --- | --- | --- |
| `u_superadmin` | superadmin | `______________` |
| `u_admin` | admin | `______________` |
| `u_seller` | seller | `______________` |
| `u_buyer` | buyer | `______________` |
| `u_support` | support | `______________` |
| `u_common_user` | common_user | `______________` |
| `u_user_not_registered` | user_not_registered | `______________` |
