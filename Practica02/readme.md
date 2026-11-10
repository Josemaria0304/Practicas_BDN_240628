# Documentacion de la Practica 02: Conexiones Remotas a Bases de Datos
 Práctica 02 · Conexiones Remotas a Bases de Datos Relacionales

**MySQL · Windows 11 · Red local · Git/GitHub**

| | |
|---|---|
| Asignatura | Bases de Datos en la Nube |
| Grupo | 7A |
| Estudiante | Jose Maria Castillo Aparicio - 240628 |
| Fecha | 5/11/2026 |

## Descripción

Se configura un entorno cliente-servidor para establecer conexiones remotas a una base de datos relacional MySQL, usando Windows 11 y la red local del Laboratorio de Cómputo.

El escenario reproduce elementos que después aparecen en Bases de Datos en la Nube: direccionamiento IP, puertos, Firewall, servicios, autenticación remota, usuarios, privilegios, roles, auditoría, carga masiva y procedimientos almacenados.

Se utiliza la base **`db_test`** con una tabla **`tb_users`** (simula usuarios de un e-commerce) y una tabla **`tb_logs`** (registra los cambios detonados por triggers). Un usuario con rol `seller` realiza una importación masiva desde un CSV con `LOAD DATA LOCAL INFILE`; `local_infile` se habilita solo durante la prueba y se deshabilita al concluir.

Todo el trabajo se versiona en GitHub como portafolio de evidencias: scripts, documentación, CSV de prueba, capturas y conclusiones.

## Objetivo general

Implementar y documentar un entorno cliente-servidor con MySQL sobre Windows 11 que permita conexiones remotas dentro de una red local, administrando puertos, servicio, Firewall, usuarios, privilegios, roles, auditoría, carga masiva desde CSV y procedimientos de Soft Delete, con Git/GitHub como portafolio técnico y preparación para despliegues en nube.

## Resultados esperados

- Configurar un servidor MySQL para conexiones locales y remotas.
- Relacionar dirección IP, puerto TCP, Firewall y servicio del sistema operativo.
- Administrar el servicio MySQL sobre Windows 11.
- Crear y documentar estructuras relacionales para pruebas.
- Implementar auditoría automática mediante triggers.
- Crear usuarios remotos y administrar privilegios.
- Diseñar, asignar y activar roles RBAC.
- Establecer conexiones cliente-servidor e identificar la sesión efectiva.
- Realizar una importación masiva remota desde CSV con `LOAD DATA LOCAL INFILE`.
- Gestionar de forma temporal una capacidad sensible y restaurar su estado seguro.
- Implementar procedimientos almacenados y Soft Delete.
- Usar Git/GitHub como control de versiones y portafolio profesional.

## Arquitectura lógica

```
PC CLIENTE - Windows 11
  mysql.exe + usuario + rol + CSV local
        |  TCP/IP: IP + Puerto
        v
RED LAN DEL LABORATORIO
        |
        v
PC SERVIDOR - Windows 11
  Firewall -> Puerto MySQL -> Servicio MySQL
                                  |
                                  v
                              db_test
        tb_users -> Triggers -> tb_logs
        Usuarios -> Roles -> Privilegios
        Procedimiento -> Soft Delete
                ^
                | LOAD DATA LOCAL INFILE
                |
        CSV ubicado en el PC cliente

Git local <-> GitHub: scripts + documentación + evidencias
```

## Estructura del repositorio

```
Practicas_7A_BDN_240628/
├── README.md
└── practica_02_conexiones_remotas/
    ├── README.md
    ├── sql/          01_database.sql, 02_tables.sql, 03_triggers.sql,
    │                 04_users.sql, 05_roles.sql, 06_soft_delete.sql
    ├── csv/          usuarios_masivos.csv
    ├── evidencias/   capturas
    └── docs/
```

> No subir contraseñas reales, archivos `.env`, respaldos con datos sensibles ni capturas que expongan credenciales. Añadir `.gitignore` cuando sea necesario.

## Actividades

### 1. Repositorio remoto y portafolio de evidencias

Repositorio sugerido: `Practicas_7A_BDN_<MATRICULA>` (guía del docente: `MTI-MarcoRH/Praticas_BDN_MATRICULA`).

```bash
git init
git branch -M main
git remote add origin <URL_REPOSITORIO>
git add .
git commit -m "docs: estructura inicial de la practica"
git push -u origin main
```

**Evidencia:** URL del repositorio, estructura inicial, README y primer commit.

### 2. Entorno local, Firewall y verificación de comunicación

Se identifican nombre del equipo, IPv4, máscara de subred, puerta de enlace, versión de MySQL y nombre del servicio. Se consulta el Firewall de Microsoft Defender (solo se desactiva temporalmente como diagnóstico y se reactiva al terminar). Desde un segundo equipo se prueba la comunicación hacia el servidor y, si es posible, la inversa.

```
hostname
ipconfig
ping <IP_SERVIDOR>
mysql --version
```



### 3. Puerto de MySQL mediante `my.ini`

Se consulta el puerto actual, se localiza `my.ini`, se hace copia de seguridad y se modifica `port` en la sección `[mysqld]` con el valor asignado por el docente. Se crea una regla de entrada del Firewall que permita solo ese puerto TCP.

```sql
SHOW VARIABLES LIKE 'port';
```
```ini
[mysqld]
port=<NUEVO_PUERTO>
```
```
netstat -ano | findstr <NUEVO_PUERTO>
```

**Evidencia:** puerto original, fragmento editado de `my.ini` y regla de Firewall.
**Punto de control:** el servicio debe poder reiniciarse y el puerto no debe estar ocupado por otro proceso.

### 4. Administración del servicio y comprobación del nuevo puerto

```
services.msc
net stop MySQL80
net start MySQL80
netstat -ano | findstr <NUEVO_PUERTO>
```

**Evidencia:** servicio detenido/iniciado y puerto en estado de escucha.

### 5. Conexión local con el nuevo puerto

```
mysql -u root -p --port=<NUEVO_PUERTO>
mysql -h localhost -P <NUEVO_PUERTO> -u root -p
```
```sql
SELECT VERSION();
SHOW VARIABLES LIKE 'port';
```

Parámetros: `-h` (host), `-P` (puerto), `-u` (usuario), `-p` (solicita contraseña).
**Punto de control:** la conexión local debe funcionar antes de diagnosticar una remota.

### 6. Creación de `db_test`, `tb_users` y `tb_logs`

```sql
CREATE DATABASE db_test;
USE db_test;
DESCRIBE tb_users;
DESCRIBE tb_logs;
```

- `tb_users`: identificador, nombre, apellidos, email, nickname, `password_hash`, estado, fecha de registro, último acceso, última actualización y fecha de eliminación lógica.
- `tb_logs`: tabla afectada, tipo de operación, usuario de conexión, descripción detallada, fecha/hora y estatus.

**Evidencia:** `sql/01_database.sql`, `sql/02_tables.sql` y capturas de `DESCRIBE`.

### 7. Triggers de auditoría sobre `tb_users`

Tres triggers (`trg_users_after_insert`, `trg_users_after_update`, `trg_users_after_delete`) que insertan en `tb_logs`.
El de `UPDATE` describe solo los campos cuyo valor cambió, comparando NULL de forma segura con `<=>`. El responsable se registra con `USER()`.

**Evidencia:** `sql/03_triggers.sql` y registros de prueba en `tb_logs`.

### 8. Usuarios remotos y privilegios directos

```sql
CREATE USER 'usuario'@'%' IDENTIFIED BY '<PASSWORD>';
GRANT SELECT, INSERT, UPDATE ON db_test.* TO 'usuario'@'%';
SHOW GRANTS FOR 'usuario'@'%';
```

Se comparan los hosts `localhost`, `%` y una IP específica, aplicando mínimo privilegio.
**Evidencia:** `sql/04_users.sql` y capturas de `CREATE USER` / `SHOW GRANTS`.
**Punto de control:** nunca publicar contraseñas de laboratorio en el repositorio.

### 9. Roles, privilegios, asignación y activación (RBAC)

```sql
CREATE ROLE 'superadmin', 'admin', 'support', 'seller';
GRANT SELECT, INSERT, UPDATE ON db_test.tb_users TO 'seller';
GRANT 'seller' TO 'usuario'@'%';
SET DEFAULT ROLE 'seller' TO 'usuario'@'%';
SELECT CURRENT_ROLE();
```

Matriz orientativa de roles:

| Rol | SELECT | INSERT | UPDATE | DELETE | Administración |
|---|---|---|---|---|---|
| seller | Sí | Sí | Sí | No | No |
| support | Sí | No | Sí | No | No |
| admin | Sí | Sí | Sí | Sí | Objetos de `db_test` |
| superadmin | Sí | Sí | Sí | Sí | Administración ampliada de laboratorio |

**Evidencia:** `sql/05_roles.sql` y tabla Usuario – Rol – Privilegios.

### 10. Conexión remota e identificación de la sesión

```
mysql -u <USUARIO> -h <IP_SERVIDOR> --port=<PUERTO> -p
```
```sql
SELECT USER();
SELECT CURRENT_USER();
SELECT CURRENT_ROLE();
SHOW DATABASES;
```

**Evidencia:** captura completa de la conexión y de las consultas de identidad.
**Punto de control:** si PING funciona pero MySQL no conecta, revisar puerto, Firewall, usuario@host y estado del servicio.

### 11. Pruebas de inserción, modificación, eliminación y auditoría

Desde la conexión remota se ejecutan `INSERT`, `SELECT`, `UPDATE` y, si el rol lo permite, `DELETE` sobre `tb_users`. Se intenta al menos una operación no autorizada para observar el error de permisos y se consulta la bitácora:

```sql
SELECT * FROM tb_logs ORDER BY operation_date ASC;
```

**Evidencia:** operaciones permitidas, una denegada y los registros generados en `tb_logs`.

### 12. Prueba colaborativa con roles del grupo

Se asignan temporalmente los perfiles: 1 superadmin, 1 admin, 1 support y 2 sellers. Todos ejecutan la misma batería (`SELECT`, `INSERT`, `UPDATE`, `DELETE`, `CREATE TABLE`, `DROP TABLE` y consulta de bitácora) para construir una matriz permitido/denegado.

**Evidencia:** matriz de permisos reales por rol, errores representativos y conclusiones sobre mínimo privilegio.

### 13. Importación masiva remota desde CSV con rol `seller`

CSV de datos ficticios (250–500 registros), ubicado en `csv/`:

```
first_name,last_name,email,nickname,password_hash,status
Ana,López,ana001@example.test,ana001,$2y$demo,active
Luis,Pérez,luis002@example.test,luis002,$2y$demo,active
```

Secuencia segura de habilitación temporal:

| Paso | Quién | Acción |
|---|---|---|
| 1 | Administrador | `SHOW GLOBAL VARIABLES LIKE 'local_infile';` |
| 2 | Administrador | `SET GLOBAL local_infile = ON;` |
| 3 | Seller (cliente) | `mysql --local-infile=1 -u <SELLER> -h <IP_SERVIDOR> -P <PUERTO> -p` |
| 4 | Seller | Ejecutar `LOAD DATA LOCAL INFILE` y comprobar `ROW_COUNT()`/`COUNT(*)` |
| 5 | Administrador | `SET GLOBAL local_infile = OFF;` |
| 6 | Verificación | `SHOW GLOBAL VARIABLES LIKE 'local_infile';` (debe regresar `OFF`) |

```sql
LOAD DATA LOCAL INFILE 'C:/ruta/usuarios_masivos.csv'
INTO TABLE tb_users
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(first_name, last_name, email, nickname, password_hash, status);

SELECT COUNT(*) FROM tb_users;
SELECT * FROM tb_logs ORDER BY operation_date DESC;
```

No se requiere el privilegio global `FILE`; sí los privilegios sobre la tabla. Se registra `COUNT(*)` antes y después. Si no se reconocen los saltos de línea, revisar `LINES TERMINATED BY` (en Windows, `\r\n`).

**Evidencia:** CSV en `csv/`, estado OFF/ON/OFF de `local_infile`, conexión con `--local-infile=1`, filas importadas y registros en `tb_logs`.

### 14. Procedimiento almacenado para Soft Delete

Se usan los campos `status`/`is_active` y `deleted_at` de `tb_users`. El procedimiento `soft_delete_user` marca el registro como inactivo y asigna la fecha de eliminación lógica; el trigger `AFTER UPDATE` registra el cambio.

```sql
CALL soft_delete_user(<ID_USUARIO>);
SELECT * FROM tb_users WHERE id = <ID_USUARIO>;
SELECT * FROM tb_logs ORDER BY operation_date DESC;
```

**Evidencia:** `sql/06_soft_delete.sql`, ejecución del procedimiento y registros en `tb_users` y `tb_logs`.
**Punto de control:** el registro no desaparece físicamente y el cambio queda auditado.

### 15. Consolidación de evidencias y publicación

README completo (descripción, objetivo, arquitectura, configuración, scripts, roles, prueba remota, carga masiva, auditoría, Soft Delete, problemas, soluciones y conclusiones), repositorio sin información sensible y commits significativos:

```
docs: crea estructura inicial
config: documenta red y puerto MySQL
feat: crea base, tablas y triggers
feat: agrega usuarios, roles y privilegios
test: documenta pruebas remotas
feat: agrega importacion masiva CSV
feat: implementa soft delete
docs: completa evidencias y conclusiones
```

**Evidencia:** URL final, historial de commits, README completo y estructura ordenada.

## Problemas encontrados y soluciones

| Problema | Diagnóstico | Solución |
|---|---|---|
| _(describir)_ | _(cómo se diagnosticó)_ | _(qué se hizo)_ |

## Reflexión y cierre

1. ¿Qué diferencia existe entre una dirección IP y un puerto TCP?
2. ¿Por qué una prueba PING exitosa no garantiza que MySQL acepte una conexión?
3. ¿Por qué es preferible abrir únicamente el puerto necesario en el Firewall?
4. ¿Qué diferencia existe entre `USER()` y `CURRENT_USER()` en MySQL?
5. ¿Qué aporta un rol frente a asignar privilegios individualmente?
6. ¿Qué evidencia produce un trigger de auditoría que no produciría una tabla sin bitácora?
7. ¿Por qué `LOAD DATA LOCAL INFILE` es apropiado cuando el CSV está en el equipo cliente?
8. ¿Qué riesgos existen al mantener `local_infile` habilitado permanentemente?
9. ¿Qué efecto tiene una importación de cientos de filas sobre `tb_logs` si existe un trigger `AFTER INSERT`?
10. ¿Por qué un seller no debería recibir privilegios administrativos para una carga masiva?
11. ¿Qué ventajas ofrece Soft Delete frente a `DELETE` físico?
12. ¿Qué elementos de esta práctica permanecerían al migrar MySQL a un VPS?
13. ¿Qué controles adicionales serían necesarios si el servidor estuviera expuesto a Internet?
14. ¿Qué información del repositorio demuestra mejor las competencias del estudiante ante un reclutador?
15. ¿Qué problemas enfrentó durante la práctica y cómo los diagnosticó?

_Respuestas: (redactar de forma argumentada, con base en la evidencia obtenida)._

## Referencias técnicas

- Oracle. MySQL 8.4 Reference Manual – Security Considerations for LOAD DATA LOCAL.
- Oracle. MySQL 8.4 Reference Manual – mysql Client Options (`--local-infile`).
- Oracle. MySQL 8.4 Reference Manual – Server System Variable `local_infile`.


