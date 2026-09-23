
-- 1. CREACION DE USUARIOS REMOTOS
CREATE USER IF NOT EXISTS 'angel.barrios'@'%' IDENTIFIED BY '240196'; -- super admin 
CREATE USER IF NOT EXISTS 'marco.ramirez'@'%' IDENTIFIED BY 'qwerty123'; -- Profe
CREATE USER IF NOT EXISTS 'luis.cazarez'@'%' IDENTIFIED BY '240343'; -- suport 
CREATE USER IF NOT EXISTS 'escamilla.vargas'@'%' IDENTIFIED BY '240687';
CREATE USER IF NOT EXISTS 'saul.barrios'@'%' IDENTIFIED BY '240196'; -- derecha

CREATE USER IF NOT EXISTS 'adrian.gomez'@'%' IDENTIFIED BY '240165';

-- 2. ASIGNACION DE PRIVILEGIOS DE SUPERUSUARIO
GRANT ALL PRIVILEGES ON . TO 'jose.castillo'@'%';

GRANT SELECT, INSERT, UPDATE, DELETE
ON db_test.*
TO 'luis.cazarez'@'%';


-- 3. CREACION DE ROLES PARA ECOMMERCE
CREATE ROLE IF NOT EXISTS 'superadmin';
CREATE ROLE IF NOT EXISTS 'admin';
CREATE ROLE IF NOT EXISTS 'seller';
CREATE ROLE IF NOT EXISTS 'buyer';
CREATE ROLE IF NOT EXISTS 'support';
CREATE ROLE IF NOT EXISTS 'common';
CREATE ROLE IF NOT EXISTS 'user_not_registered';

-- 4. ASIGNACION DE PRIVILEGIOS A LOS ROLES
GRANT ALL PRIVILEGES ON . TO 'superadmin';
-- ADMIN
GRANT ALL PRIVILEGES ON db_test.* TO 'admin';
-- SUPPORT
GRANT SELECT, INSERT, UPDATE ON db_test.tb_users TO 'support';
GRANT SELECT, INSERT, UPDATE ON db_test.tb_products TO 'support';
-- SELLER
GRANT SELECT, INSERT, UPDATE ON db_test.tb_products TO 'seller';

-- 5. ASIGNACION DE ROLES A LOS USUARIOS
GRANT 'superadmin' TO 'jose.castillo'@'%';
GRANT 'admin' TO 'marco.ramirez'@'%';
GRANT 'support' TO 'luis.cazarez'@'%';
GRANT 'seller' TO 'adrian.gomez'@'%';
GRANT 'seller' TO 'saul.barrios'@'%';

-- 6. ACTIVACION AUTOMATICA DE ROLES PARA TODOS LOS USUARIOS (CRITICO)
SET DEFAULT ROLE ALL TO 
  'marco.ramirez'@'%', 
  'luis.cazarez'@'%', 
  'adrian.gomez'@'%';
  'saul.barrios'@'%';

-- 7. REFRESCAR PRIVILEGIOS
FLUSH PRIVILEGES;

-- MENSAJE DE CONFIRMACION
SELECT "Los usuarios y privilegios han sido creados correctamente" AS mensaje;