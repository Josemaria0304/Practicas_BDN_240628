-- =====================================================
-- 1. CREACIÓN DE USUARIOS
-- =====================================================

CREATE USER IF NOT EXISTS 'jose.castillo'@'%' IDENTIFIED BY '240628'; -- super admin 
CREATE USER IF NOT EXISTS 'marco.ramirez'@'%' IDENTIFIED BY 'qwerty123'; -- Profe
CREATE USER IF NOT EXISTS 'fernando.miguel'@'%' IDENTIFIED BY '240161'; -- support 
CREATE USER IF NOT EXISTS 'carlos.cabrera'@'%' IDENTIFIED BY '240201';
CREATE USER IF NOT EXISTS 'yuliana.mendoza'@'%' IDENTIFIED BY '240808'; -- derecha
CREATE USER IF NOT EXISTS 'adrian.gomez'@'%' IDENTIFIED BY '240165';
CREATE USER IF NOT EXISTS 'hector.morales'@'%' IDENTIFIED BY '240763'; 

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
CREATE ROLE IF NOT EXISTS 'common_user';
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

GRANT SELECT
ON db_test.tb_products TO 'common_user';

GRANT
    'user_not_registered',
    'common_user',
    'buyer'
TO 'app.web'@'%';



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

--- GRANT SELECT, INSERT, UPDATE ON db_test.tbd_carts_items TO 'buyer';

--- GRANT SELECT, INSERT ON db_test.tb_buyer_orders TO 'buyer';

GRANT SELECT
ON db_test.tb_products
TO 'common_user'@'%';

GRANT SELECT, INSERT, UPDATE ON db_test.tbd_users_wishlist_proudcts TO 'buyer';
-- =====================================================
-- 7. ASIGNACIÓN DE ROLES A USUARIOS
-- =====================================================

GRANT 'superadmin' TO 'jose.castillo'@'%';

GRANT 'admin' TO 'marco.ramirez'@'%';

GRANT 'support' TO 'fernando.miguel'@'%';

GRANT 'seller' TO 'adrian.gomez'@'%';

GRANT 'seller' TO 'yuliana.mendoza'@'%';


GRANT 'user_not_registered' TO 'app.web'@'%';

GRANT 'user_not_registered' TO 'app.movil'@'%';


-- =====================================================
-- 8. ACTIVACIÓN AUTOMÁTICA DE ROLES
-- =====================================================

SET DEFAULT ROLE ALL TO
    'jose.castillo'@'%',
    'marco.ramirez'@'%',
    'fernando.miguel'@'%',
    'adrian.gomez'@'%',
    'yuliana.mendoza'@'%',
    'app.web'@'%',
    'app.movil'@'%';



-- =====================================================
-- 9. VERIFICACIÓN
-- =====================================================

SELECT 'Usuarios, roles y privilegios configurados'
AS mensaje;

-- mysql