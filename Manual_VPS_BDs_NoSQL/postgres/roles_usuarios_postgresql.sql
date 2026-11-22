-- roles_usuarios_postgresql.sql
-- Los mismos roles y usuarios del script de MySQL, aplicados a PostgreSQL (base db_test_u2)
-- Se puede ejecutar varias veces. Antes de subirlo a GitHub, reemplaza las contraseñas por 'CAMBIAR'.

-- 1. ROLES (sin inicio de sesión, igual que los roles de MySQL)
DO $$
DECLARE r text;
BEGIN
  FOREACH r IN ARRAY ARRAY['superadmin', 'admin', 'seller', 'buyer', 'support', 'common_user', 'user_not_registered'] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
      EXECUTE format('CREATE ROLE %I NOLOGIN', r);
    END IF;
  END LOOP;
END $$;

-- 2. SUPERADMIN: todo, y puede dar permisos (WITH GRANT OPTION)
ALTER ROLE superadmin CREATEDB CREATEROLE;
GRANT ALL PRIVILEGES ON DATABASE db_test_u2 TO superadmin WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON SCHEMA public TO superadmin WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO superadmin WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO superadmin WITH GRANT OPTION;

-- 3. ADMIN: todo sobre db_test_u2
GRANT ALL PRIVILEGES ON DATABASE db_test_u2 TO admin;
GRANT ALL PRIVILEGES ON SCHEMA public TO admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO superadmin, admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO superadmin, admin;

-- 4. SUPPORT
GRANT SELECT, INSERT, UPDATE ON tb_users TO support;
GRANT SELECT, UPDATE ON tb_products TO support;
GRANT SELECT, INSERT, UPDATE ON tbc_categories TO support;
GRANT SELECT, INSERT, UPDATE ON tbd_products_categories TO support;
-- En MySQL support también ejecuta sp_soft_delete_user; ese procedimiento no existe en PostgreSQL
-- porque la conversión no incluye procedimientos.

-- 5. SELLER
GRANT SELECT, INSERT, UPDATE ON tb_products TO seller;
GRANT SELECT ON tbc_categories TO seller;

-- 6. BUYER
GRANT SELECT, INSERT, UPDATE ON tbd_users_wishlist_proudcts TO buyer;

-- 7. COMMON_USER
GRANT SELECT ON tb_products TO common_user;

-- 8. USER_NOT_REGISTERED: puede registrarse
GRANT INSERT ON tb_people TO user_not_registered;
GRANT INSERT ON tb_users TO user_not_registered;

-- Todos los roles pueden entrar a la base y ver el esquema
GRANT CONNECT ON DATABASE db_test_u2 TO superadmin, admin, seller, buyer, support, common_user, user_not_registered;
GRANT USAGE ON SCHEMA public TO superadmin, admin, seller, buyer, support, common_user, user_not_registered;

-- 9. USUARIOS (con inicio de sesión)
DO $$
DECLARE u record;
BEGIN
  FOR u IN SELECT * FROM (VALUES
      ('jose.castillo', '240628'),
      ('marco.ramirez', 'qwerty123'),
      ('fernando.miguel', '240161'),
      ('carlos.cabrera', '240201'),
      ('yuliana.mendoza', '240808'),
      ('adrian.gomez', '240165'),
      ('hector.morales', '240763'),
      ('app.web', 'web123'),
      ('app.movil', 'mobile890')
    ) AS t(usuario, clave) LOOP
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = u.usuario) THEN
      EXECUTE format('ALTER ROLE %I WITH LOGIN PASSWORD %L', u.usuario, u.clave);
    ELSE
      EXECUTE format('CREATE ROLE %I WITH LOGIN PASSWORD %L', u.usuario, u.clave);
    END IF;
  END LOOP;
END $$;

-- 10. ASIGNACIÓN DE ROLES (en PostgreSQL quedan activos al iniciar sesión, como SET DEFAULT ROLE ALL)
GRANT superadmin TO "jose.castillo";
GRANT admin TO "marco.ramirez";
GRANT support TO "fernando.miguel";
GRANT seller TO "adrian.gomez";
GRANT seller TO "yuliana.mendoza";
GRANT user_not_registered, common_user, buyer TO "app.web";
GRANT user_not_registered TO "app.movil";

-- 11. VERIFICACIÓN
SELECT r.rolname AS rol, string_agg(m.rolname, ', ' ORDER BY m.rolname) AS usuarios
FROM pg_roles r
LEFT JOIN pg_auth_members am ON am.roleid = r.oid
LEFT JOIN pg_roles m ON m.oid = am.member
WHERE r.rolname IN ('superadmin', 'admin', 'seller', 'buyer', 'support', 'common_user', 'user_not_registered')
GROUP BY r.rolname ORDER BY r.rolname;

SELECT 'Usuarios, roles y privilegios configurados' AS mensaje;
