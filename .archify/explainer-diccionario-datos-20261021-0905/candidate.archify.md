# Diccionario de datos de `db_test`

El esquema contiene 19 tablas y 147 columnas; este diccionario explica su propósito y documenta cada campo según el respaldo MySQL.

- Basado en `Respaldo-20261020.sql` y su DDL MySQL 8.0.
- Incluye descripciones generales para cada entidad y columna.
- Distingue claves, nulabilidad, evaluación, origen y naturaleza del dato.
- Detalla tipos, formatos, valores por defecto y restricciones declaradas.

@answer scope="Esquema físico de db_test según el respaldo MySQL 8.0."
@meta locale=es

## Alcance y convenciones {#alcance}
Este diccionario describe el esquema definido en `Respaldo-20261020.sql` (MySQL 8.0, InnoDB, `utf8mb4`). Incluye las 19 tablas físicas, sus columnas, claves y restricciones declaradas en ese respaldo; no infiere reglas que no estén expresadas en el DDL.

- **Llave primaria:** `Sí` identifica la PK; `No` no es PK; `Llave Foránea` indica referencia a otra tabla. Si una columna es simultáneamente PK y FK, se indica `Sí; Llave Foránea`.
- **Obligatoriedad:** sigue la declaración `NOT NULL` del DDL. Una columna sin `NOT NULL` se clasifica como opcional, aunque tenga valor predeterminado. `GENERATED` sin `NOT NULL` se describe según su nulabilidad declarada.
- **Evaluación:** todos los campos son **Monovaluados**: cada columna almacena un valor escalar por fila. Una relación de varios valores se representa mediante filas relacionadas, no mediante una columna multivaluada.
- **Origen:** **Derivado** solo para expresiones generadas en el esquema; el resto es **Almacenado**, incluidos valores insertados por defecto y marcas de tiempo automáticas.
- **Naturaleza:** IDs numéricos son **Cualitativos** (identificadores nominales), no magnitudes; cantidades, importes y coordenadas son **Cuantitativos**. Fechas, estados y textos son cualitativos.
- **Composición:** forma sintáctica o estructura formal del valor; **Dominio** especifica el tipo MySQL, rango representable, valores por defecto, claves y reglas efectivamente declaradas.
- `NULL` y `DEFAULT` se consideran por separado. El respaldo no define `CHECK` en una columna salvo cuando se indica expresamente en su dominio.

## `tb_carts` ? — carrito asociado al usuario {#tb-carts}

**Descripción general:** Registra el carrito principal de cada usuario y su estado temporal. El índice único sobre `user_ID` limita la tabla a un carrito por usuario; la tabla hija `tbd_shopping_cart` almacena los productos y cantidades del carrito.

| Nombre de la columna | Descripción general | Llave primaria | Obligatoriedad | Evaluación de valor | Origen del dato | Naturaleza del dato | Composición (anotación formal) | Dominio |
|---|---|---|---|---|---|---|---|---|
| `ID` | Identificador del carrito. | Sí | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Entero natural autogenerado | `INT UNSIGNED AUTO_INCREMENT`; PK. |
| `user_ID` | Usuario propietario del carrito. | Llave Foránea | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Referencia a usuario | `INT UNSIGNED`; FK → `tb_users.ID`; `UNIQUE (user_ID)` impone como máximo un carrito por usuario. |
| `status` | Indicador binario de estado del carrito. | No | Opcional (`NULL`) | Monovaluado | Almacenado | Cualitativa (binaria) | Bit `0` o `1` | `BIT(1) DEFAULT b'1'`; admite `NULL`; no hay `CHECK`. |
| `creation_date` | Fecha y hora de creación del registro. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora `YYYY-MM-DD HH:MM:SS` | `DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP`. |
| `last_update` | Fecha y hora de la última modificación. | No | Opcional (`NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora o `NULL` | `DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP`. |

## `tb_logs` ? — bitácora de operaciones {#tb-logs}

**Descripción general:** Conserva entradas de auditoría con objeto afectado, operación, usuario de base de datos, descripción, fecha y resultado. El respaldo incluye triggers que registran operaciones de inserción, actualización y eliminación en varias tablas; el DDL de esta tabla no restringe `table_name` a nombres existentes.

| Nombre de la columna | Descripción general | Llave primaria | Obligatoriedad | Evaluación de valor | Origen del dato | Naturaleza del dato | Composición (anotación formal) | Dominio |
|---|---|---|---|---|---|---|---|---|
| `ID` | Identificador de la entrada de bitácora. | Sí | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Entero autogenerado | `INT AUTO_INCREMENT`; PK. |
| `table_name` | Nombre lógico de la tabla relacionada con el evento. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa | Cadena de hasta 100 caracteres | `VARCHAR(100)`; sin enumeración ni FK declarada. |
| `operation` | Tipo de operación registrada. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (categórica) | `enum{Create, Read, Update, Delete}` | `ENUM('Create','Read','Update','Delete') NOT NULL`. |
| `db_user` | Usuario o identidad de conexión que ejecutó la operación. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa | Cadena de hasta 80 caracteres | `VARCHAR(80)`. |
| `description` | Texto libre con el detalle del evento y, cuando aplique, cambios realizados. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa | Texto de longitud variable | `TEXT`; límite efectivo según MySQL. |
| `operation_date` | Fecha y hora de registro de la operación. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora | `DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP`. |
| `operation_status` | Indicador binario del resultado/estado de la operación. | No | Opcional (`NULL`) | Monovaluado | Almacenado | Cualitativa (binaria) | Bit `0` o `1` | `BIT(1) DEFAULT b'1'`; admite `NULL`; no hay `CHECK`. |

## `tb_products` ? — catálogo de productos {#tb-products}

**Descripción general:** Catálogo base de productos ofrecidos en la aplicación. Contiene SKU, información descriptiva, precio, existencia y estado. Otras tablas lo referencian para categorías, ofertas, carritos, listas de deseos y detalles de pedidos.

| Nombre de la columna | Descripción general | Llave primaria | Obligatoriedad | Evaluación de valor | Origen del dato | Naturaleza del dato | Composición (anotación formal) | Dominio |
|---|---|---|---|---|---|---|---|---|
| `ID` | Identificador interno del producto. | Sí | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Entero natural autogenerado | `INT UNSIGNED AUTO_INCREMENT`; PK. |
| `SKU` | Código de inventario/identificación comercial. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa | Cadena de hasta 50 caracteres | `VARCHAR(50)`; `UNIQUE`; no hay patrón `CHECK` declarado. |
| `name` | Nombre del producto. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa | Cadena de hasta 250 caracteres | `VARCHAR(250)`. |
| `description` | Descripción textual del producto. | No | Opcional (`NULL`) | Monovaluado | Almacenado | Cualitativa | Texto de longitud variable o `NULL` | `TEXT`. |
| `current_price` | Precio vigente del producto. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cuantitativa (monetaria) | Decimal con 10 dígitos, 2 decimales | `DECIMAL(10,2) NOT NULL DEFAULT 0.00`; no hay `CHECK` que impida negativos. |
| `current_stock` | Existencia actual reportada. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cuantitativa (conteo) | Entero no negativo | `INT UNSIGNED NOT NULL DEFAULT 0`; rango MySQL `0`–`4,294,967,295`. |
| `status` | Indicador binario de disponibilidad/estado. | No | Opcional (`NULL`) | Monovaluado | Almacenado | Cualitativa (binaria) | Bit `0` o `1` | `BIT(1) DEFAULT b'1'`; admite `NULL`; no hay `CHECK`. |
| `creation_date` | Fecha y hora de alta. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora | `DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP`. |
| `last_update` | Fecha y hora de modificación más reciente. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora | `DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP`. |

## `tb_seller_orders` ? — pedidos de vendedor {#tb-seller-orders}

**Descripción general:** Representa la parte de un pedido gestionada por un vendedor, con subtotal, costo de envío y estado de cumplimiento. `seller_ID` apunta a un usuario que actúa como vendedor; `tbd_order_items` contiene los artículos asociados.

| Nombre de la columna | Descripción general | Llave primaria | Obligatoriedad | Evaluación de valor | Origen del dato | Naturaleza del dato | Composición (anotación formal) | Dominio |
|---|---|---|---|---|---|---|---|---|
| `ID` | Identificador del pedido de vendedor. | Sí | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Entero natural autogenerado | `INT UNSIGNED AUTO_INCREMENT`; PK. |
| `seller_ID` | Identificador del usuario vendedor. | Llave Foránea | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Referencia a usuario | `INT UNSIGNED`; FK → `tb_users.ID`. |
| `subtotal` | Importe subtotal de los artículos del pedido. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cuantitativa (monetaria) | Decimal con 12 dígitos, 2 decimales | `DECIMAL(12,2) NOT NULL DEFAULT 0.00`; `CHECK (subtotal >= 0)`. |
| `shipping_cost` | Importe del costo de envío. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cuantitativa (monetaria) | Decimal con 12 dígitos, 2 decimales | `DECIMAL(12,2) NOT NULL DEFAULT 0.00`; `CHECK (shipping_cost >= 0)`. |
| `fulfillment_status` | Etapa de preparación/entrega del pedido. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (categórica) | `enum{Pending, Accepted, Preparing, Sent, Delivered, Canceled, Returned}` | `ENUM(...) NOT NULL DEFAULT 'Pending'`. |
| `status` | Indicador binario de estado activo. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (binaria) | Bit `0` o `1` | `BIT(1) NOT NULL DEFAULT b'1'`. |
| `creation_date` | Fecha y hora de creación. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora | `DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP`. |
| `last_update` | Fecha y hora de la última modificación. | No | Opcional (`NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora o `NULL` | `DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP`. |

## `tb_user_addresses` ? — direcciones de usuario {#tb-user-addresses}

**Descripción general:** Almacena domicilios de entrega vinculados a usuarios, incluyendo datos de destinatario, instrucciones, coordenadas, selección predeterminada y estado. Las restricciones requieren que latitud y longitud se capturen juntas y que se mantengan dentro de rangos geográficos válidos.

| Nombre de la columna | Descripción general | Llave primaria | Obligatoriedad | Evaluación de valor | Origen del dato | Naturaleza del dato | Composición (anotación formal) | Dominio |
|---|---|---|---|---|---|---|---|---|
| `ID` | Identificador de la dirección. | Sí | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Entero natural autogenerado | `BIGINT UNSIGNED AUTO_INCREMENT`; PK. |
| `user_ID` | Usuario propietario de la dirección. | Llave Foránea | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Referencia a usuario | `INT UNSIGNED`; FK → `tb_users.ID`; índice `idx_user_addresses`. |
| `address_label` | Etiqueta asignada por el usuario (por ejemplo, hogar o trabajo). | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa | Cadena de hasta 100 caracteres | `VARCHAR(100)`; sin catálogo declarado. |
| `recipient_name` | Nombre de la persona que recibirá el envío. | No | Opcional (`NULL`) | Monovaluado | Almacenado | Cualitativa | Cadena de hasta 150 caracteres o `NULL` | `VARCHAR(150)`. |
| `recipient_phone` | Teléfono de contacto del destinatario. | No | Opcional (`NULL`) | Monovaluado | Almacenado | Cualitativa | Cadena de hasta 25 caracteres o `NULL` | `VARCHAR(25)`; no hay validación de formato declarada. |
| `delivery_instructions` | Indicaciones complementarias para la entrega. | No | Opcional (`NULL`) | Monovaluado | Almacenado | Cualitativa | Cadena de hasta 500 caracteres o `NULL` | `VARCHAR(500)`. |
| `latitude` | Latitud geográfica de la dirección. | No | Opcional (`NULL`) | Monovaluado | Almacenado | Cuantitativa (coordenada) | Decimal con 10 dígitos, 7 decimales | `DECIMAL(10,7)`; `CHECK (-90 <= latitude <= 90)`; debe ser `NULL` junto con `longitude` o ambas presentes. |
| `longitude` | Longitud geográfica de la dirección. | No | Opcional (`NULL`) | Monovaluado | Almacenado | Cuantitativa (coordenada) | Decimal con 10 dígitos, 7 decimales | `DECIMAL(10,7)`; `CHECK (-180 <= longitude <= 180)`; debe ser `NULL` junto con `latitude` o ambas presentes. |
| `is_default` | Indica si la dirección está marcada como predeterminada. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (binaria) | Entero booleano `0` o `1` | `TINYINT(1) NOT NULL DEFAULT 0`; no hay `CHECK` explícito. |
| `status` | Indicador binario de estado activo. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (binaria) | Bit `0` o `1` | `BIT(1) NOT NULL DEFAULT b'1'`. |
| `creation_date` | Fecha y hora de creación. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora | `DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP`. |
| `last_update` | Fecha y hora de última modificación. | No | Opcional (`NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora o `NULL` | `DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP`. |

## `tb_users` ? — usuarios {#tb-users}

**Descripción general:** Entidad base de identidad de la aplicación. Guarda datos de acceso, identificadores únicos, fechas de actividad y estado; múltiples entidades operativas dependen de su `ID`.

| Nombre de la columna | Descripción general | Llave primaria | Obligatoriedad | Evaluación de valor | Origen del dato | Naturaleza del dato | Composición (anotación formal) | Dominio |
|---|---|---|---|---|---|---|---|---|
| `ID` | Identificador interno del usuario. | Sí | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Entero natural autogenerado | `INT UNSIGNED AUTO_INCREMENT`; PK. |
| `email` | Correo electrónico del usuario. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa | Cadena de hasta 80 caracteres | `VARCHAR(80)`; `UNIQUE`; no se declara `CHECK` de formato. |
| `nickname` | Nombre visible o alias del usuario. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa | Cadena de hasta 100 caracteres | `VARCHAR(100)`; `UNIQUE`. |
| `password` | Representación de la credencial de acceso. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa | Cadena de hasta 255 caracteres | `VARCHAR(255)`; el DDL no especifica algoritmo ni regla de almacenamiento. |
| `creation_date` | Fecha y hora de registro del usuario. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora | `DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP`. |
| `last_update` | Fecha y hora de la modificación más reciente. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora | `DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP`. |
| `last_login` | Fecha y hora del acceso más reciente conocido. | No | Opcional (`NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora o `NULL` | `DATETIME DEFAULT NULL`. |
| `status` | Indicador binario del estado de la cuenta. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (binaria) | Bit `0` o `1` | `BIT(1) NOT NULL DEFAULT b'1'`. |

## `tbb_orders` ? — pedidos de clientes {#tbb-orders}

**Descripción general:** Cabecera del pedido realizado por un usuario. Conserva una clave de negocio, totales, estado y marcas de tiempo; sus detalles y pagos se registran en tablas dependientes.

| Nombre de la columna | Descripción general | Llave primaria | Obligatoriedad | Evaluación de valor | Origen del dato | Naturaleza del dato | Composición (anotación formal) | Dominio |
|---|---|---|---|---|---|---|---|---|
| `ID` | Identificador interno del pedido. | Sí | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Entero natural autogenerado | `INT UNSIGNED AUTO_INCREMENT`; PK. |
| `key` | Clave externa/de negocio del pedido. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Cadena de hasta 40 caracteres | `VARCHAR(40)`; `UNIQUE`; sin patrón `CHECK` declarado. |
| `User_ID` | Identificador del usuario que realizó el pedido. | Llave Foránea | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Referencia a usuario | `INT UNSIGNED`; FK → `tb_users.ID`; índice `idx_orders_user`. |
| `total_products` | Número total de productos reportado para el pedido. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cuantitativa (conteo) | Entero con signo | `INT NOT NULL`; sin valor predeterminado ni `CHECK` declarado. |
| `total_cost` | Importe total del pedido. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cuantitativa (monetaria) | Decimal con 10 dígitos, 3 decimales | `DECIMAL(10,3) NOT NULL DEFAULT 0.000`; no hay `CHECK` declarado. |
| `status_string` | Estado funcional del pedido. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (categórica) | `enum{Registered, Wishlist, Payed, Canceled, Delivered, Devolved, Attended, Sended}` | `ENUM('Registered','Wishlist','Payed','Canceled','Delivered','Devolved','Attended','Sended') NOT NULL DEFAULT 'Registered'`; se conservan las grafías del esquema. |
| `status` | Indicador binario de estado activo. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (binaria) | Bit `0` o `1` | `BIT(1) NOT NULL DEFAULT b'1'`. |
| `creation_date` | Fecha y hora de creación del pedido. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora | `DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP`. |
| `last_update` | Fecha y hora de última modificación. | No | Opcional (`NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora o `NULL` | `DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP`. |

## `tbc_categories` ? — categorías jerárquicas {#tbc-categories}

**Descripción general:** Catálogo de categorías de productos. `sup_id_category` permite una jerarquía autorreferenciada; la asociación de productos con categorías se materializa en `tbd_products_categories`.

| Nombre de la columna | Descripción general | Llave primaria | Obligatoriedad | Evaluación de valor | Origen del dato | Naturaleza del dato | Composición (anotación formal) | Dominio |
|---|---|---|---|---|---|---|---|---|
| `ID` | Identificador de categoría. | Sí | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Entero natural autogenerado | `INT UNSIGNED AUTO_INCREMENT`; PK. |
| `name` | Nombre de la categoría. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa | Cadena de hasta 120 caracteres | `VARCHAR(120)`; `UNIQUE`. |
| `description` | Descripción de la categoría. | No | Opcional (`NULL`) | Monovaluado | Almacenado | Cualitativa | Texto de longitud variable o `NULL` | `TEXT`. |
| `sup_id_category` | Categoría superior, si existe. | Llave Foránea | Opcional (`NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Referencia autorreferenciada o `NULL` | `INT UNSIGNED`; FK → `tbc_categories.ID`; índice `fk_superior_category`. |
| `status` | Indicador binario de estado activo. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (binaria) | Bit `0` o `1` | `BIT(1) NOT NULL DEFAULT b'1'`. |
| `creation_date` | Fecha y hora de creación. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora | `DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP`. |
| `last_update` | Fecha y hora de la última modificación. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora | `DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP`. |

## `tbc_payment_methods` ? — catálogo de métodos de pago {#tbc-payment-methods}

**Descripción general:** Catálogo de métodos de pago disponibles para registrar pagos. `tbd_payments` lo utiliza como referencia; es distinto del catálogo de tipos de medio de pago guardado por usuarios (`tbc_payment_methods_types`).

| Nombre de la columna | Descripción general | Llave primaria | Obligatoriedad | Evaluación de valor | Origen del dato | Naturaleza del dato | Composición (anotación formal) | Dominio |
|---|---|---|---|---|---|---|---|---|
| `payment_method_ID` | Identificador del método de pago. | Sí | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Entero natural autogenerado | `INT UNSIGNED AUTO_INCREMENT`; PK. |
| `method_name` | Nombre del método de pago. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa | Cadena de hasta 60 caracteres | `VARCHAR(60)`; `UNIQUE`. |
| `description` | Descripción del método. | No | Opcional (`NULL`) | Monovaluado | Almacenado | Cualitativa | Cadena de hasta 255 caracteres o `NULL` | `VARCHAR(255)`. |
| `status` | Indicador binario de disponibilidad del método. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (binaria) | Bit `0` o `1` | `BIT(1) NOT NULL DEFAULT b'1'`. |
| `creation_date` | Fecha y hora de alta. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora | `DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP`. |
| `last_update` | Fecha y hora de modificación más reciente. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora | `DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP`. |

## `tbc_payment_methods_types` ? — tipos de medios de pago guardados {#tbc-payment-methods-types}

**Descripción general:** Catálogo de tipos/códigos de medio de pago asociados a instrumentos que un usuario guarda. `tbd_user_payment_methods.payment_method_type_ID` referencia esta tabla.

| Nombre de la columna | Descripción general | Llave primaria | Obligatoriedad | Evaluación de valor | Origen del dato | Naturaleza del dato | Composición (anotación formal) | Dominio |
|---|---|---|---|---|---|---|---|---|
| `ID` | Identificador del tipo de medio de pago. | Sí | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Entero natural autogenerado | `INT UNSIGNED AUTO_INCREMENT`; PK. |
| `code` | Código único del tipo de medio de pago. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa | Cadena de hasta 30 caracteres | `VARCHAR(30)`; `UNIQUE`. |
| `description` | Descripción del tipo de medio de pago. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa | Texto de longitud variable | `TEXT`. |
| `status` | Indicador binario de disponibilidad del tipo. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (binaria) | Bit `0` o `1` | `BIT(1) NOT NULL DEFAULT b'1'`. |
| `creation_date` | Fecha y hora de alta. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora | `DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP`. |
| `last_update` | Fecha y hora de última modificación. | No | Opcional (`NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora o `NULL` | `DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP`. |

## `tbd_address_components` ? — componentes jerárquicos de dirección {#tbd-address-components}

**Descripción general:** Descompone una dirección en componentes textuales (por ejemplo, partes de una dirección) y permite anidar componentes mediante `address_sup_ID`. La clave foránea compuesta padre garantiza que el componente superior pertenezca a la misma dirección.

| Nombre de la columna | Descripción general | Llave primaria | Obligatoriedad | Evaluación de valor | Origen del dato | Naturaleza del dato | Composición (anotación formal) | Dominio |
|---|---|---|---|---|---|---|---|---|
| `ID` | Identificador del componente. | Sí | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Entero natural autogenerado | `BIGINT UNSIGNED AUTO_INCREMENT`; PK. |
| `address_ID` | Dirección a la que pertenece el componente. | Llave Foránea | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Referencia a dirección | `BIGINT UNSIGNED`; FK → `tb_user_addresses.ID`; también participa en `UNIQUE (address_ID, ID)` y en la FK compuesta autorreferenciada. |
| `value` | Valor textual del componente de dirección. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa | Cadena de hasta 255 caracteres | `VARCHAR(255)`. |
| `component_type` | Tipo o categoría textual del componente. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa | Cadena de hasta 50 caracteres | `VARCHAR(50)`; no se define catálogo/`ENUM` ni `CHECK`. |
| `status` | Indicador binario de estado activo. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (binaria) | Bit `0` o `1` | `BIT(1) NOT NULL DEFAULT b'1'`. |
| `address_sup_ID` | ID del componente padre de la misma dirección; `NULL` representa que no se declara padre. | Llave Foránea | Opcional (`NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Referencia autorreferenciada compuesta o `NULL` | `BIGINT UNSIGNED`; junto con `address_ID` referencia `(address_ID, ID)` de `tbd_address_components`; `ON DELETE RESTRICT`; índice `(address_ID,address_sup_ID)`. |
| `creation_date` | Fecha y hora de creación. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora | `DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP`. |
| `last_update` | Fecha y hora de última modificación. | No | Opcional (`NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora o `NULL` | `DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP`. |

## `tbd_order_details` ? — renglones de pedido {#tbd-order-details}

**Descripción general:** Detalla los productos incluidos en un pedido de cliente, con cantidad y precio unitario capturado. El subtotal se calcula y almacena automáticamente como cantidad por precio unitario.

| Nombre de la columna | Descripción general | Llave primaria | Obligatoriedad | Evaluación de valor | Origen del dato | Naturaleza del dato | Composición (anotación formal) | Dominio |
|---|---|---|---|---|---|---|---|---|
| `order_detail_ID` | Identificador del renglón de pedido. | Sí | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Entero natural autogenerado | `INT UNSIGNED AUTO_INCREMENT`; PK. |
| `order_ID` | Pedido al que pertenece el renglón. | Llave Foránea | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Referencia a pedido | `INT UNSIGNED`; FK → `tbb_orders.ID`; índice `idx_order_details_order`. |
| `product_ID` | Producto incluido en el renglón. | Llave Foránea | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Referencia a producto | `INT UNSIGNED`; FK → `tb_products.ID`; índice `idx_order_details_product`. |
| `quantity` | Unidades del producto incluidas en el renglón. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cuantitativa (conteo) | Entero natural positivo | `INT UNSIGNED NOT NULL DEFAULT 1`; `CHECK (quantity > 0)`. |
| `unit_price` | Precio unitario aplicado al renglón. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cuantitativa (monetaria) | Decimal con 10 dígitos, 2 decimales | `DECIMAL(10,2) NOT NULL`; `CHECK (unit_price >= 0)`. |
| `subtotal` | Importe del renglón, calculado a partir de cantidad y precio. | No | Opcional según DDL (`NULL` no prohibido) | Monovaluado | Derivado | Cuantitativa (monetaria) | `quantity × unit_price`; decimal con 12 dígitos, 2 decimales | `DECIMAL(12,2) GENERATED ALWAYS AS (quantity * unit_price) STORED`; no admite escritura directa ordinaria; los operandos están declarados `NOT NULL`. |
| `creation_date` | Fecha y hora de creación del renglón. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora | `DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP`. |
| `last_update` | Fecha y hora de última modificación. | No | Opcional (`NULL` no prohibido) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora | `DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP`; admite `NULL` según DDL. |

## `tbd_order_items` ? — artículos de pedidos de vendedor {#tbd-order-items}

**Descripción general:** Detalla los productos incluidos en una orden de vendedor. Conserva el nombre y precio unitario en el momento del pedido, además de identificar la oferta/proveedor. El subtotal es una columna generada; los IDs `product_ID` y `provider_ID` apuntan a columnas de `tbd_users_offer_products` según el DDL existente.

| Nombre de la columna | Descripción general | Llave primaria | Obligatoriedad | Evaluación de valor | Origen del dato | Naturaleza del dato | Composición (anotación formal) | Dominio |
|---|---|---|---|---|---|---|---|---|
| `ID` | Identificador del artículo de la orden. | Sí | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Entero natural autogenerado | `INT UNSIGNED AUTO_INCREMENT`; PK. |
| `seller_order_ID` | Orden de vendedor que contiene el artículo. | Llave Foránea | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Referencia a orden de vendedor | `INT UNSIGNED`; FK → `tb_seller_orders.ID`; índice. |
| `product_ID` | Producto de la oferta comprada. | Llave Foránea | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Referencia a oferta de producto | `INT UNSIGNED`; FK → `tbd_users_offer_products.product_ID`; índice. |
| `provider_ID` | Usuario proveedor asociado a la oferta. | Llave Foránea | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Referencia a oferta/proveedor | `INT UNSIGNED`; FK → `tbd_users_offer_products.user_ID`; índice. |
| `product_name` | Nombre del producto conservado en el renglón. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa | Cadena de hasta 255 caracteres | `VARCHAR(255)`. |
| `quantity` | Unidades solicitadas. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cuantitativa (conteo) | Entero natural positivo | `INT UNSIGNED NOT NULL`; `CHECK (quantity > 0)`. |
| `unit_price` | Precio unitario registrado para la venta. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cuantitativa (monetaria) | Decimal con 12 dígitos, 2 decimales | `DECIMAL(12,2) NOT NULL`; `CHECK (unit_price >= 0)`. |
| `subtotal` | Importe de la línea, derivado de cantidad por precio unitario. | No | Opcional según DDL (`NULL` no prohibido) | Monovaluado | Derivado | Cuantitativa (monetaria) | `quantity × unit_price`; decimal con 12 dígitos, 2 decimales | `DECIMAL(12,2) GENERATED ALWAYS AS (...) STORED`; los operandos son `NOT NULL`. |
| `creation_date` | Fecha y hora de creación del artículo. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora | `DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP`. |

## `tbd_payments` ? — pagos de pedidos {#tbd-payments}

**Descripción general:** Registra intentos/resultados de pago asociados a pedidos, el método utilizado, el importe, una referencia transaccional opcional y la fecha efectiva de pago. El estado está limitado a los valores enumerados por el DDL.

| Nombre de la columna | Descripción general | Llave primaria | Obligatoriedad | Evaluación de valor | Origen del dato | Naturaleza del dato | Composición (anotación formal) | Dominio |
|---|---|---|---|---|---|---|---|---|
| `payment_ID` | Identificador del registro de pago. | Sí | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Entero natural autogenerado | `INT UNSIGNED AUTO_INCREMENT`; PK. |
| `order_ID` | Pedido al que corresponde el pago. | Llave Foránea | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Referencia a pedido | `INT UNSIGNED`; FK → `tbb_orders.ID`; índice `idx_payments_order`. |
| `payment_method_ID` | Método de pago utilizado. | Llave Foránea | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Referencia al catálogo de métodos | `INT UNSIGNED`; FK → `tbc_payment_methods.payment_method_ID`; índice `idx_payments_method`. |
| `amount` | Importe del pago. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cuantitativa (monetaria) | Decimal con 12 dígitos, 2 decimales | `DECIMAL(12,2) NOT NULL`; `CHECK (amount > 0)`. |
| `payment_status` | Estado del proceso de pago. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (categórica) | `enum{Pendiente, Procesando, Pagado, Rechazado, Reembolsado, Cancelado}` | `ENUM(...) NOT NULL DEFAULT 'Pendiente'`. |
| `transaction_reference` | Referencia externa de la transacción, si está disponible. | No | Opcional (`NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Cadena de hasta 100 caracteres o `NULL` | `VARCHAR(100)`; índice `UNIQUE`; MySQL permite múltiples `NULL` en esta clave única. |
| `payment_date` | Fecha y hora de pago, si se completó. | No | Opcional (`NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora o `NULL` | `DATETIME DEFAULT NULL`. |
| `creation_date` | Fecha y hora de creación del registro de pago. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora | `DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP`. |
| `last_update` | Fecha y hora de la última modificación. | No | Opcional (`NULL` no prohibido) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora | `DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP`; admite `NULL` según DDL. |

## `tbd_products_categories` ? — relación producto-categoría {#tbd-products-categories}

**Descripción general:** Tabla de asociación muchos-a-muchos entre productos y categorías. La clave primaria compuesta evita repetir una misma pareja categoría-producto.

| Nombre de la columna | Descripción general | Llave primaria | Obligatoriedad | Evaluación de valor | Origen del dato | Naturaleza del dato | Composición (anotación formal) | Dominio |
|---|---|---|---|---|---|---|---|---|
| `category_ID` | Categoría asociada al producto. | Sí; Llave Foránea | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Parte de PK compuesta y referencia | `INT UNSIGNED`; PK `(category_ID, product_ID)`; FK → `tbc_categories.ID`. |
| `product_ID` | Producto asociado a la categoría. | Sí; Llave Foránea | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Parte de PK compuesta y referencia | `INT UNSIGNED`; PK `(category_ID, product_ID)`; FK → `tb_products.ID`; índice `fk_product`. |
| `status` | Indicador binario de estado de la asociación. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (binaria) | Bit `0` o `1` | `BIT(1) NOT NULL DEFAULT b'1'`. |
| `creation_date` | Fecha y hora de creación de la asociación. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora | `DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP`. |
| `last_update` | Fecha y hora de última modificación. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora | `DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP`. |

## `tbd_shopping_cart` ? — artículos del carrito {#tbd-shopping-cart}

**Descripción general:** Registra productos y cantidades en el carrito de cada usuario. La clave única `(user_ID, product_ID)` permite como máximo una fila por producto y usuario; la cantidad debe ser positiva.

| Nombre de la columna | Descripción general | Llave primaria | Obligatoriedad | Evaluación de valor | Origen del dato | Naturaleza del dato | Composición (anotación formal) | Dominio |
|---|---|---|---|---|---|---|---|---|
| `cart_item_ID` | Identificador del renglón de carrito. | Sí | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Entero natural autogenerado | `INT UNSIGNED AUTO_INCREMENT`; PK. |
| `user_ID` | Usuario propietario del renglón. | Llave Foránea | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Referencia a usuario | `INT UNSIGNED`; FK → `tb_users.ID` con `ON DELETE CASCADE`; parte de `UNIQUE (user_ID, product_ID)`. |
| `product_ID` | Producto incluido en el carrito. | Llave Foránea | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Referencia a producto | `INT UNSIGNED`; FK → `tb_products.ID`; índice `idx_cart_product`; parte de `UNIQUE (user_ID, product_ID)`. |
| `quantity` | Unidades del producto agregadas al carrito. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cuantitativa (conteo) | Entero natural positivo | `INT UNSIGNED NOT NULL DEFAULT 1`; `CHECK (quantity > 0)`. |
| `creation_date` | Fecha y hora de incorporación del renglón. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora | `DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP`. |
| `last_update` | Fecha y hora de última modificación del renglón. | No | Opcional (`NULL` no prohibido) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora | `DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP`; admite `NULL` según DDL. |

## `tbd_user_payment_methods` ? — medios de pago de usuarios {#tbd-user-payment-methods}

**Descripción general:** Asocia usuarios con medios de pago tokenizados o gestionados por un proveedor externo. Guarda la referencia del proveedor en lugar de definir en esta tabla un número completo de cuenta; `last_four` es opcional.

| Nombre de la columna | Descripción general | Llave primaria | Obligatoriedad | Evaluación de valor | Origen del dato | Naturaleza del dato | Composición (anotación formal) | Dominio |
|---|---|---|---|---|---|---|---|---|
| `ID` | Identificador del medio de pago de usuario. | Sí | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Entero natural autogenerado | `BIGINT UNSIGNED AUTO_INCREMENT`; PK. |
| `user_ID` | Usuario propietario del medio de pago. | Llave Foránea | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Referencia a usuario | `INT UNSIGNED`; FK → `tb_users.ID`; índice. |
| `payment_method_type_ID` | Tipo de medio de pago guardado. | Llave Foránea | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Referencia a catálogo de tipos | `INT UNSIGNED`; FK → `tbc_payment_methods_types.ID`; índice. |
| `provider` | Nombre del proveedor de pagos externo. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa | Cadena de hasta 60 caracteres | `VARCHAR(60)`; participa en `UNIQUE (provider, provider_method_ref)`. |
| `provider_method_ref` | Token/referencia del medio de pago en el proveedor. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Cadena de hasta 255 caracteres | `VARCHAR(255)`; participa en `UNIQUE (provider, provider_method_ref)`. |
| `label` | Etiqueta descriptiva elegida para el medio de pago. | No | Opcional (`NULL`) | Monovaluado | Almacenado | Cualitativa | Cadena de hasta 100 caracteres o `NULL` | `VARCHAR(100)`. |
| `last_four` | Últimos cuatro caracteres visibles del identificador de pago. | No | Opcional (`NULL`) | Monovaluado | Almacenado | Cualitativa | Cadena fija de 4 caracteres o `NULL` | `CHAR(4)`; sin validación de que sean dígitos. |
| `is_default` | Indica si el medio está seleccionado como predeterminado. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (binaria) | Entero booleano `0` o `1` | `TINYINT(1) NOT NULL DEFAULT 0`; no hay `CHECK` explícito. |
| `status` | Indicador binario de estado activo. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (binaria) | Bit `0` o `1` | `BIT(1) NOT NULL DEFAULT b'1'`. |
| `creation_date` | Fecha y hora de registro. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora | `DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP`. |
| `last_update` | Fecha y hora de última modificación. | No | Opcional (`NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora o `NULL` | `DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP`. |

## `tbd_users_offer_products` ? — ofertas de productos por usuario {#tbd-users-offer-products}

**Descripción general:** Relaciona un producto del catálogo con un usuario oferente y registra tipo de propiedad, disponibilidad, existencias y fechas. `user_ID` admite `NULL`, por lo que el DDL permite ofertas sin usuario asociado.

| Nombre de la columna | Descripción general | Llave primaria | Obligatoriedad | Evaluación de valor | Origen del dato | Naturaleza del dato | Composición (anotación formal) | Dominio |
|---|---|---|---|---|---|---|---|---|
| `product_offer_ID` | Identificador de la oferta. | Sí | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Entero natural autogenerado | `INT UNSIGNED AUTO_INCREMENT`; PK. |
| `user_ID` | Usuario asociado a la oferta. | Llave Foránea | Opcional (`NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Referencia a usuario o `NULL` | `INT UNSIGNED`; FK → `tb_users.ID`; índice `idx_offer_user`. |
| `product_ID` | Producto del catálogo que se ofrece. | Llave Foránea | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Referencia a producto | `INT UNSIGNED`; FK → `tb_products.ID`; índice `idx_offer_product`. |
| `type_ownership` | Relación de propiedad/comercialización del oferente. | No | Opcional (`NULL`) | Monovaluado | Almacenado | Cualitativa (categórica) | `enum{Owner, Reseller, Distributor}` o `NULL` | `ENUM('Owner','Reseller','Distributor') DEFAULT NULL`. |
| `available_stock` | Cantidad disponible reportada para la oferta. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cuantitativa (conteo) | Entero natural | `INT UNSIGNED NOT NULL DEFAULT 1`; rango `0`–`4,294,967,295`. |
| `status` | Indicador binario de estado de la oferta. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (binaria) | Bit `0` o `1` | `BIT(1) NOT NULL DEFAULT b'1'`. |
| `creation_date` | Fecha y hora de registro de la oferta. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora | `DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP`. |
| `available_date` | Fecha y hora desde la que está disponible. | No | Opcional (`NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora o `NULL` | `DATETIME DEFAULT NULL`. |
| `last_update` | Fecha y hora de última modificación. | No | Opcional (`NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora o `NULL` | `DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP`. |

## `tbd_users_wishlist_proudcts` ? — lista de deseos {#tbd-users-wishlist-proudcts}

**Descripción general:** Relaciona usuarios con productos guardados en su lista de deseos. El nombre físico de la tabla contiene la grafía `proudcts` y se conserva tal cual aparece en el respaldo. La PK compuesta impide duplicar un mismo producto para el mismo usuario.

| Nombre de la columna | Descripción general | Llave primaria | Obligatoriedad | Evaluación de valor | Origen del dato | Naturaleza del dato | Composición (anotación formal) | Dominio |
|---|---|---|---|---|---|---|---|---|
| `user_ID` | Usuario propietario de la entrada de lista. | Sí; Llave Foránea | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Parte de PK compuesta y referencia | `INT UNSIGNED`; PK `(user_ID, product_ID)`; FK → `tb_users.ID`. |
| `product_ID` | Producto guardado en la lista. | Sí; Llave Foránea | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (identificador) | Parte de PK compuesta y referencia | `INT UNSIGNED`; PK `(user_ID, product_ID)`; FK → `tb_products.ID`; índice `fk_products3`. |
| `status` | Indicador binario de estado de la relación. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (binaria) | Bit `0` o `1` | `BIT(1) NOT NULL DEFAULT b'1'`. |
| `creation_date` | Fecha y hora de incorporación a la lista. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora | `DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP`. |
| `last_update` | Fecha y hora de última modificación. | No | Obligatorio (`NOT NULL`) | Monovaluado | Almacenado | Cualitativa (temporal) | Fecha-hora | `DATETIME NOT NULL ON UPDATE CURRENT_TIMESTAMP`; no declara valor `DEFAULT`. |

## Observaciones de integridad del esquema {#observaciones}
- El respaldo declara **19 tablas**. Hay tablas de asociación con claves primarias compuestas (`tbd_products_categories` y `tbd_users_wishlist_proudcts`) y una FK compuesta autorreferenciada en `tbd_address_components`.
- Los únicos `CHECK` explícitos están en direcciones (`chk_coordinates`, `chk_latitude`, `chk_longitude`), pedidos de vendedor (`subtotal`, `shipping_cost`), detalles/artículos de pedido (`quantity`, `unit_price`) y carrito (`quantity`), además de las restricciones indicadas en cada dominio.
- En `tbd_order_items`, las referencias de `product_ID` y `provider_ID` se consignan exactamente como aparecen: hacia `tbd_users_offer_products.product_ID` y `.user_ID`. El DDL no declara una clave única compuesta para garantizar que ambos identificadores pertenezcan a la misma fila de oferta.
- `tb_carts` y `tbd_shopping_cart` representan estructuras distintas en el esquema: la primera mantiene un registro único por usuario; la segunda almacena renglones producto-usuario.
- El esquema no define unidad monetaria, formato de teléfono/correo, catálogo de `component_type`, ni una regla de unicidad para marcar un único registro predeterminado por usuario. No se presuponen esas reglas en las tablas descriptivas.
