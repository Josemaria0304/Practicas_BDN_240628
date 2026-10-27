-- 1. CREACIÓN DE USUARIOS
CREATE USER IF NOT EXISTS 'angel.barrios'@'%' IDENTIFIED BY '240196'; -- super admin 
CREATE USER IF NOT EXISTS 'marco.ramirez'@'%' IDENTIFIED BY 'qwerty123'; -- Profe
CREATE USER IF NOT EXISTS 'luis.cazarez'@'%' IDENTIFIED BY '240343'; -- support 
CREATE USER IF NOT EXISTS 'escamilla.vargas'@'%' IDENTIFIED BY '240687';
CREATE USER IF NOT EXISTS 'saul.barrios'@'%' IDENTIFIED BY '240196'; -- derecha
CREATE USER IF NOT EXISTS 'adrian.gomez'@'%' IDENTIFIED BY '240165';
CREATE USER IF NOT EXISTS 'jose.castillo'@'%' IDENTIFIED BY '12345'; 


-- 5. ASIGNACIÓN DE ROLES
GRANT 'superadmin' TO 'jose.castillo'@'%';

-- 6. ACTIVACIÓN AUTOMÁTICA DE ROLES (Incluir a jose.castillo)

-- 2. ASIGNACIÓN DIRECTA DE PRIVILEGIOS
GRANT ALL PRIVILEGES ON *.* TO 'jose.castillo'@'%'; 

-- 1. CREACIÓN DE USUARIOS
CREATE USER IF NOT EXISTS 'angel.barrios'@'%' IDENTIFIED BY '240196'; -- super admin 
CREATE USER IF NOT EXISTS 'marco.ramirez'@'%' IDENTIFIED BY 'qwerty123'; -- Profe
CREATE USER IF NOT EXISTS 'luis.cazarez'@'%' IDENTIFIED BY '240343'; -- support 
CREATE USER IF NOT EXISTS 'escamilla.vargas'@'%' IDENTIFIED BY '240687';
CREATE USER IF NOT EXISTS 'saul.barrios'@'%' IDENTIFIED BY '240196'; -- derecha
CREATE USER IF NOT EXISTS 'adrian.gomez'@'%' IDENTIFIED BY '240165';
CREATE USER IF NOT EXISTS 'jose.castillo'@'%' IDENTIFIED BY '240628'; 

-- 2. ASIGNACIÓN DIRECTA DE PRIVILEGIOS
GRANT ALL PRIVILEGES ON *.* TO 'jose.castillo'@'%'; 

GRANT SELECT, INSERT, UPDATE, DELETE
ON db_test.*
TO 'luis.cazarez'@'%';

-- 3. CREACIÓN DE ROLES PARA ECOMMERCE
CREATE ROLE IF NOT EXISTS 'superadmin';
CREATE ROLE IF NOT EXISTS 'admin';
CREATE ROLE IF NOT EXISTS 'seller';
CREATE ROLE IF NOT EXISTS 'buyer';
CREATE ROLE IF NOT EXISTS 'support';
CREATE ROLE IF NOT EXISTS 'common';
CREATE ROLE IF NOT EXISTS 'user_not_registered';

-- 4. ASIGNACIÓN DE PRIVILEGIOS A LOS ROLES
GRANT ALL PRIVILEGES ON *.* TO 'superadmin'; -- Corregido: ON *.*
-- ADMIN
GRANT ALL PRIVILEGES ON db_test.* TO 'admin';
-- SUPPORT
GRANT SELECT, INSERT, UPDATE ON db_test.tb_users TO 'support';
GRANT SELECT, UPDATE ON db_test.tb_products TO 'support';
GRANT SELECT, INSERT, UPDATE ON db_test.tbc_categories TO 'support';
GRANT SELECT, INSERT, UPDATE ON db_test.tbd_products_categories TO 'support';

-- SELLER
GRANT SELECT, INSERT, UPDATE ON db_test.tb_products TO 'seller';
GRANT SELECT ON db_test.tbc_categories TO 'seller';

-- 5. ASIGNACIÓN DE ROLES A LOS USUARIOS
GRANT 'superadmin' TO 'jose.castillo'@'%';
GRANT 'admin' TO 'marco.ramirez'@'%';
GRANT 'support' TO 'luis.cazarez'@'%';
GRANT 'seller' TO 'adrian.gomez'@'%';
GRANT 'seller' TO 'saul.barrios'@'%';

-- 6. ACTIVACIÓN AUTOMÁTICA DE ROLES PARA TODOS LOS USUARIOS (CRÍTICO)
SET DEFAULT ROLE ALL TO 
  'marco.ramirez'@'%', 
  'luis.cazarez'@'%', 
  'adrian.gomez'@'%', 
  'saul.barrios'@'%';
  ; -- Corregido: cambiada la coma por el punto y coma final

-- 7. REFRESCAR PRIVILEGIOS
FLUSH PRIVILEGES;

-- MENSAJE DE CONFIRMACIÓN
SELECT "Los usuarios y privilegios han sido creados correctamente" AS mensaje;