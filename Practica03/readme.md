# Documentacion de la Practica 03: Manipulacion de Datos, Relaciones, Procedimientos, Funciones y Eventos en Conexiones Remotas.

Manipulación de datos, relaciones, procedimientos, funciones y eventos en conexiones remotas.
Base de datos **`db_test`** (MySQL 8.4) desplegada en un VPS. Resumen basado en el respaldo `Dump20261104.sql`.

## 1. Modelo relacional

El respaldo contiene **27 tablas** con sus llaves primarias, foráneas y restricciones:

- **24 tablas operativas** auditadas con triggers y vistas: `tb_users`, `tb_people`, `tb_products`, `tb_carts`, `tb_user_addresses`, `tb_payment_transactions`, `tb_cancellations`, `tb_refunds`, `tb_returns`, `tb_shipments`, `tb_seller_orders`, `tbb_orders`, `tbc_categories`, `tbc_payment_methods`, `tbc_payment_methods_types`, `tbd_address_components`, `tbd_order_details`, `tbd_order_items`, `tbd_payments`, `tbd_products_categories`, `tbd_shopping_cart`, `tbd_user_payment_methods`, `tbd_users_offer_products`, `tbd_users_wishlist_proudcts`.
- **1 tabla de bitácora:** `tb_logs`.
- **2 tablas adicionales** sin triggers ni vistas de trazabilidad: `tb_buyer_orders` y `tbd_carts_items`.

## 2. Triggers y auditoría

- **72 triggers** (`AFTER INSERT`, `AFTER UPDATE`, `AFTER DELETE` × 24 tablas operativas).
- Cada trigger escribe en `tb_logs`: tabla afectada, operación (`Create`/`Read`/`Update`/`Delete`), usuario de conexión (`db_user`), fecha, descripción del cambio y estado.
- `tb_logs` acumula **58,149 registros** (23-oct-2026 a 02-nov-2026).

## 3. Vistas SQL

- **25 vistas:** 24 de trazabilidad (`vw_trazabilidad_*`, una por tabla operativa) y **`vw_total_products_by_category`**.
- Las vistas de trazabilidad cruzan cada tabla con la bitácora e incluyen usuario de BD, roles, detalle, fecha y estado de la operación.
- `vw_total_products_by_category` muestra ruta y nivel de la categoría, total de productos, activos, inactivos y sin categoría.

## 4. Usuarios, roles y privilegios remotos

Roles definidos por el manual: `superadmin`, `admin`, `support`, `seller`, `buyer`, `common_user`, `user_not_registered`.
Las cuentas, roles y privilegios no se incluyen en el respaldo (se guardan en los scripts de configuración de acceso).
En la bitácora aparecen conexiones remotas distintas por usuario (por ejemplo `luis.cazarez@PC-05`, `adrian.gomez@PC-18`, `saul.barrios@PC-06`, `app.web@PC-015`).

## 5. Procedimientos, funciones y eventos

**Procedimiento general parametrizable:** `sp_generate_users(cantidad, país, edad_mín, edad_máx, contraseña, OUT primer_ID, OUT último_ID, OUT creados)`.
Valida parámetros con `SIGNAL`, maneja errores con handlers, usa ciclo `WHILE` con límite de intentos y registra cada usuario con `sp_register_user`.

**Procedimientos de apoyo (13 en total):**

| Procedimiento | Función |
|---|---|
| `sp_register_user` | Alta de usuario y persona |
| `sp_generate_us_users` | Lote de usuarios de EE. UU. |
| `sp_generate_young_global_users` | Lote de usuarios jóvenes de varios países |
| `sp_generate_mixed_status_users` | Lote con porcentaje de cuentas inactivas |
| `sp_deactivate_users_in_range` | Desactiva un porcentaje de usuarios de un rango |
| `sp_summarize_user_batch` | Resumen de un lote |
| `sp_seed_all_test_users` | Ejecuta los lotes de simulación |
| `sp_soft_delete_user` / `_product` / `_category` / `_product_category`, `sp_restore_product` | Bajas lógicas y restauración |

**Funciones auxiliares (15, prefijo `fn_gen_`):** fecha de nacimiento, país aleatorio, cultura por país, nombre, apellido, género, título de cortesía, correo, dominio de correo, nickname, contraseña, teléfono, dígitos aleatorios, entero aleatorio y slug ASCII.

**Eventos:** el respaldo no contiene eventos de MySQL.

## 6. Simulación masiva de usuarios

Generados el 29-oct-2026 con el procedimiento general; **10,222 usuarios simulados** con su registro en `tb_people`:

| Lote | Usuarios | Alcance | Edades | Estado |
|---|---|---|---|---|
| 1 | 1,000 | Estados Unidos | 18–65 | 1,000 activas |
| 2 | 2,000 | 17 países | 18–30 | 2,000 activas |
| 3 | 7,222 | 17 países | 18–65 | 6,139 activas / 1,083 inactivas (15 %) |

- Género generado aleatoriamente (`Masculino`, `Femenino`, `Prefiero no decirlo`).
- Total en `tb_users`: 10,229 (incluye cuentas previas de prueba); `tb_people`: 10,223.
- Las inserciones quedaron registradas en `tb_logs` con el usuario `root@localhost`.

## 7. Población de productos por vendedores remotos

- **15,007 productos** en `tb_products`: **13,570 activos** y **1,437 descontinuados** (`status = b'0'`).
- Inserciones auditadas: `adrian.gomez@PC-18` (10,000) y `saul.barrios@PC-06` (5,000), más 7 registros adicionales de pruebas.
- SKU únicos, sin duplicados; precios de 19.00 a 24,999.00 y existencias de 0 a 350.
- **100 categorías** (12 principales y 88 subcategorías) y **21,474 relaciones** en `tbd_products_categories`.
- 11,800 productos tienen categoría asignada; 3,207 aún no tienen.
- Las categorías con productos son 50; en ellas hay entre 22 y 5,098 productos.

## 8. Consultas de verificación

Conteos ejecutados sobre el respaldo (tablas, triggers, vistas, rutinas, usuarios, productos, categorías y bitácora) respaldan las cifras de este documento.

## 9. Respaldos

- `Dump20261104.sql` incluye estructura, datos, triggers, vistas y rutinas.

## 10 y 11. Documentación técnica y GitHub

- Modelo Entidad-Relación Extendido y Diccionario de Datos con **Archify**: _por agregar_.
- Rama **`Practica03`** fusionada con la rama principal: _por agregar_.

