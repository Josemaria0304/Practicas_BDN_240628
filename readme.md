# Practica 01: Insersion de datos remotos.

Este proyecto contiene el script de base de datos para la gestión de usuarios y un sistema de auditoría automatizado mediante **Triggers** en MySQL 8.0.

---

## Pasos de Creacion

1. **Inicialización del Esquema:** 
   Se creó la base de datos `db_test`, las tablas de datos/logs y se hicieron las primeras inserciones desde la cuenta de administración local (`root@localhost`).

2. **Cambio del archivo my.ini** 
   Se cambio el archivo `my.ini` para que se pudiera acceder desde cualquier equipo de la red local y se cambio al puerto 40628.

3. **Conexión Remota en Red Local:** 
   Un compañero se conectó al servidor de base de datos desde su equipo remoto (`saul.barrios@PC-06`) para realizar operaciones de prueba:
   * **Inserción:** Registro de nuevos usuarios en `tb_users`.
   * **Actualización:** Modificación de campos en usuarios existentes.
   * **Eliminación:** Borrado de registros.
   Para eso se configuro el usuario `saul.barrios` para que pueda acceder desde su equipo remoto. Tambien se quito el firewall, para que no hubiera problemas de conexion.

4. **Verificación de Auditoría:** 
   Gracias a la función `USER()` dentro de los disparadores, la tabla `tb_logs` capturó automáticamente la identidad de cada terminal/usuario que ejecutó los cambios, permitiendo diferenciar entre las operaciones de `root@localhost` y las de `saul.barrios@PC-06`.

5. **Insercion de Triggers**
Luego se insertaron los triggers, para que se pueda visualizar los cambios, creacion, registros, eliminaciones, etc. Y se realizaron pruebas para verificar que los triggers funcionaran correctamente.

## 🛠️ Estructura de la Base de Datos

La base de datos `db_test` está compuesta por dos tablas principales:

### 1. Tabla `tb_users`
Guarda la información general y credenciales de los usuarios registrados.

| Campo | Tipo | Descripción |
| :--- | :--- | :--- |
| `ID` | `INT` (PK, Auto-Increment) | Identificador único del usuario. |
| `email` | `VARCHAR(80)` (Unique) | Correo electrónico principal. |
| `nickname` | `VARCHAR(100)` (Unique) | Nombre de usuario visible. |
| `password` | `VARCHAR(255)` | Contraseña cifrada (Hash MD5/VARCHAR). |
| `creation_date` | `DATETIME` | Fecha de creación del registro (`DEFAULT CURRENT_TIMESTAMP`). |
| `last_update` | `DATETIME` | Última actualización (`ON UPDATE CURRENT_TIMESTAMP`). |
| `last_login` | `DATETIME` | Registro del último inicio de sesión. |

### 2. Tabla `tb_logs`
Almacena el registro histórico (audit log) de todas las acciones ejecutadas sobre los usuarios.

| Campo | Tipo | Descripción |
| :--- | :--- | :--- |
| `ID` | `INT` (PK, Auto-Increment) | Identificador del log. |
| `table_name` | `VARCHAR(100)` | Nombre de la tabla afectada (`tb_users`). |
| `operation` | `ENUM` | Tipo de operación: `'Create'`, `'Read'`, `'Update'`, `'Delete'`. |
| `db_user` | `VARCHAR(80)` | Usuario de la base de datos/host que realizó el cambio (`USER()`). |
| `description` | `TEXT` | Detalle específico de la operación o cambios detectados. |
| `operation_date` | `DATETIME` | Fecha y hora del evento. |
| `operation_status`| `BIT(1)` | Estado de la operación (`1` para exitoso). |

---

## ⚡ Disparadores (Triggers)

El sistema utiliza tres triggers principales para garantizar el rastreo automático de datos sin necesidad de lógica extra a nivel de aplicación:

1. **`trg_users_after_insert`**: 
   * **Momento:** `AFTER INSERT` sobre `tb_users`.
   * **Función:** Genera una entrada con la operación `'Create'` y registra los datos del usuario recién ingresado.

2. **`trg_users_after_update`**: 
   * **Momento:** `AFTER UPDATE` sobre `tb_users`.
   * **Función:** Evalúa dinámicamente qué columnas cambiaron comparando `OLD` y `NEW`. Si el `email` o el `nickname` se modifican, concatena el historial del valor anterior y el nuevo en la descripción del log.

3. **`trg_users_after_delete`**: 
   * **Momento:** `AFTER DELETE` sobre `tb_users`.
   * **Función:** Registra la baja del usuario guardando los últimos datos asociados antes de su eliminación.


```bash
mysql -u tu_usuario -p < script_db.sql