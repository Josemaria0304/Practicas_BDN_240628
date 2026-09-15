/* Creación de Usuarios Remotos */
CREATE USER IF NOT EXISTS 'jose.castillo'@'%' IDENTIFIED BY '240628';
CREATE USER IF NOT EXISTS 'marco.ramirez'@'%' IDENTIFIED BY 'qwerty123';
CREATE USER IF NOT EXISTS 'luis.cazarez'@'%' IDENTIFIED BY '240343'; -- izquierda
CREATE USER IF NOT EXISTS 'escamilla.vargas'@'%' IDENTIFIED BY '240687'; -- derecha

/* Asignación de privilegios del superusuario */
GRANT ALL PRIVILEGES ON *.* TO 'jose.castillo'@'%' WITH GRANT OPTION;

/* CREACIÓN DE ROLES PARA LA PLATAFORMA DE ECOMMERCE */
CREATE ROLE IF NOT EXISTS 'admin';
CREATE ROLE IF NOT EXISTS 'seller';
CREATE ROLE IF NOT EXISTS 'buyer';
CREATE ROLE IF NOT EXISTS 'common_user';
CREATE ROLE IF NOT EXISTS 'user_not_registered';
CREATE ROLE IF NOT EXISTS 'support';

/* Asignación de privilegios a los roles */
-- Admin
GRANT ALL PRIVILEGES ON db_test.* TO 'admin';

-- Support
GRANT SELECT, INSERT, UPDATE ON db_test.tb_users TO 'support';

/* Asignar roles a los usuarios */
GRANT 'admin' TO 'marco.ramirez'@'%';
GRANT 'support' TO 'luis.cazarez'@'%';

/* Activar los roles por defecto para que surtan efecto al iniciar sesión */
SET DEFAULT ROLE ALL TO 'marco.ramirez'@'%';
SET DEFAULT ROLE ALL TO 'luis.cazarez'@'%';

FLUSH PRIVILEGES;