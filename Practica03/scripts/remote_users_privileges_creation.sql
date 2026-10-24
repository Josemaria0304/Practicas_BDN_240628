-- =====================================================
-- 1. CREACIÓN DE USUARIOS
-- =====================================================

CREATE USER IF NOT EXISTS 'jose.castillo'@'%' IDENTIFIED BY '12345'; -- super admin 
CREATE USER IF NOT EXISTS 'marco.ramirez'@'%' IDENTIFIED BY 'qwerty123'; -- Profe
CREATE USER IF NOT EXISTS 'luis.cazarez'@'%' IDENTIFIED BY '240343'; -- support 
CREATE USER IF NOT EXISTS 'escamilla.vargas'@'%' IDENTIFIED BY '240687';
CREATE USER IF NOT EXISTS 'saul.barrios'@'%' IDENTIFIED BY '240196'; -- derecha
CREATE USER IF NOT EXISTS 'adrian.gomez'@'%' IDENTIFIED BY '240165';
-- CREATE USER IF NOT EXISTS 'jose.amaro'@'%' IDENTIFIED BY '240726'; 
CREATE USER IF NOT EXISTS 'app.web'@'%' IDENTIFIED BY 'web123';
CREATE USER IF NOT EXISTS 'app.movil'@'%' IDENTIFIED BY 'mobile890';




-- =====================================================
-- 2. CREACIÓN DE ROLES
-- =====================================================

CREATE ROLE IF NOT EXISTS 'superadmin';
CREATE ROLE IF NOT EXISTS 'admin';
CREATE ROLE IF NOT EXISTS 'seller';
CREATE ROLE IF NOT EXISTS 'buyer';
CREATE ROLE IF NOT EXISTS 'support';
CREATE ROLE IF NOT EXISTS 'common';
CREATE ROLE IF NOT EXISTS 'user_not_registered';


-- =====================================================
-- 3. PRIVILEGIOS DEL ROL SUPERADMIN
-- =====================================================

GRANT ALL PRIVILEGES ON *.* TO 'superadmin'
WITH GRANT OPTION;


-- =====================================================
-- 4. PRIVILEGIOS DEL ROL ADMIN
-- =====================================================

GRANT ALL PRIVILEGES ON db_test.* TO 'admin';


-- =====================================================
-- 5. PRIVILEGIOS DEL ROL SUPPORT
-- =====================================================

GRANT SELECT, INSERT, UPDATE
ON db_test.tb_users TO 'support';

GRANT SELECT, UPDATE
ON db_test.tb_products TO 'support';

GRANT SELECT, INSERT, UPDATE
ON db_test.tbc_categories TO 'support';

GRANT SELECT, INSERT, UPDATE
ON db_test.tbd_products_categories TO 'support';

GRANT EXECUTE ON PROCEDURE db_test.sp_soft_delete_user TO 'support'@'%';


-- =====================================================
-- 6. PRIVILEGIOS DEL ROL SELLER
-- =====================================================

GRANT SELECT, INSERT, UPDATE
ON db_test.tb_products TO 'seller';

GRANT SELECT
ON db_test.tbc_categories TO 'seller';

GRANT INSERT ON db_test.tb_people TO 'user_not_registered';

GRANT INSERT ON db_test.tb_users TO 'user_not_registered';


--- GRANT SELECT, INSERT, UPDATE ON db_test.tb_carts TO 'buyer';

--- GRANT SELECT, INSERT, UPDATE ON db_test.tb_carts_items TO 'buyer';

--- GRANT SELECT, INSERT ON db_test.tb_buyer_orders TO 'buyer';

--- GRANT SELECT, INSERT, UPDATE ON db_test.tbd_users_wishlist_proudcts TO 'buyer';
-- =====================================================
-- 7. ASIGNACIÓN DE ROLES A USUARIOS
-- =====================================================

GRANT 'superadmin' TO 'jose.castillo'@'%';

GRANT 'admin' TO 'marco.ramirez'@'%';

GRANT 'support' TO 'luis.cazarez'@'%';

GRANT 'seller' TO 'adrian.gomez'@'%';

GRANT 'seller' TO 'saul.barrios'@'%';

GRANT 'user_not_registered' TO 'app.web'@'%';

GRANT 'user_not_registered' TO 'app.movil'@'%';


-- =====================================================
-- 8. ACTIVACIÓN AUTOMÁTICA DE ROLES
-- =====================================================

SET DEFAULT ROLE ALL TO
    'jose.castillo'@'%',
    'marco.ramirez'@'%',
    'luis.cazarez'@'%',
    'adrian.gomez'@'%',
    'saul.barrios'@'%',
    'app.web'@'%',
    'app.movil'@'%';


-- =====================================================
-- 9. VERIFICACIÓN
-- =====================================================

SELECT 'Usuarios, roles y privilegios configurados'
AS mensaje;

-- mysql