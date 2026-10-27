-- =====================================================================
-- Archivo 3/3: funciones, triggers, procedimientos y vistas.
-- Ejecutar al final (después de cargar los datos del archivo 2).
-- =====================================================================

-- ---------- Función auxiliar: formato de valores para la bitácora ----------
CREATE OR REPLACE FUNCTION fn_log_fmt(p_key text, p_val jsonb)
RETURNS text
LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE
    WHEN p_val IS NULL OR jsonb_typeof(p_val) = 'null' THEN 'NULL'
    WHEN p_key = 'status' THEN CASE WHEN p_val = 'true'::jsonb THEN 'Activo' ELSE 'Inactivo' END
    ELSE p_val #>> '{}'
  END
$$;

-- ---------- Trigger genérico de auditoría hacia tb_logs ----------
-- Parámetros: TG_ARGV[0] = etiqueta del registro, TG_ARGV[1] = columnas de la llave primaria (separadas por coma)
CREATE OR REPLACE FUNCTION fn_log_cambios()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_label   text   := TG_ARGV[0];
  v_pk      text[] := string_to_array(TG_ARGV[1], ',');
  v_excl    text[] := ARRAY['password','creation_date','last_update'];
  v_row     jsonb;
  v_ids     text;
  v_detalle text;
  v_cambios text;
  v_desc    text;
  v_op      log_operation_t;
BEGIN
  IF TG_OP = 'UPDATE' THEN
    v_row := to_jsonb(NEW);
    SELECT string_agg(k || '=' || fn_log_fmt(k, v_row -> k), ', ' ORDER BY ord)
      INTO v_ids FROM unnest(v_pk) WITH ORDINALITY AS t(k, ord);
    SELECT string_agg(n.key || ': [' || fn_log_fmt(n.key, o.value) || '] -> [' || fn_log_fmt(n.key, n.value) || ']', '; ' ORDER BY n.key)
      INTO v_cambios
      FROM jsonb_each(to_jsonb(NEW)) n
      JOIN jsonb_each(to_jsonb(OLD)) o ON o.key = n.key
     WHERE n.value IS DISTINCT FROM o.value
       AND n.key <> ALL (v_excl);
    IF v_cambios IS NULL THEN
      RETURN NULL;   -- no hubo cambios relevantes
    END IF;
    v_op   := 'Update';
    v_desc := v_label || ' actualizado/a. ' || v_ids || '. Cambios: ' || v_cambios;
  ELSE
    IF TG_OP = 'INSERT' THEN v_row := to_jsonb(NEW); v_op := 'Create';
    ELSE                     v_row := to_jsonb(OLD); v_op := 'Delete';
    END IF;
    SELECT string_agg(e.key || '=' || fn_log_fmt(e.key, e.value), ', ' ORDER BY e.key)
      INTO v_detalle FROM jsonb_each(v_row) e WHERE e.key <> ALL (v_excl);
    v_desc := v_label || CASE WHEN TG_OP = 'INSERT' THEN ' creado/a. ' ELSE ' eliminado/a. ' END || v_detalle;
  END IF;

  INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
  VALUES (TG_TABLE_NAME, v_op, session_user::text, v_desc, CURRENT_TIMESTAMP, true);
  RETURN NULL;
END;
$$;

-- ---------- Reemplazo de ON UPDATE CURRENT_TIMESTAMP de MySQL ----------
CREATE OR REPLACE FUNCTION fn_set_last_update()
RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF (to_jsonb(NEW) - 'last_update') IS DISTINCT FROM (to_jsonb(OLD) - 'last_update') THEN
    NEW.last_update := CURRENT_TIMESTAMP;
  END IF;
  RETURN NEW;
END;
$$;

-- ---------- Triggers: last_update automático ----------
CREATE TRIGGER trg_tb_carts_set_last_update BEFORE UPDATE ON tb_carts FOR EACH ROW EXECUTE FUNCTION fn_set_last_update();
CREATE TRIGGER trg_tb_people_set_last_update BEFORE UPDATE ON tb_people FOR EACH ROW EXECUTE FUNCTION fn_set_last_update();
CREATE TRIGGER trg_tb_products_set_last_update BEFORE UPDATE ON tb_products FOR EACH ROW EXECUTE FUNCTION fn_set_last_update();
CREATE TRIGGER trg_tb_seller_orders_set_last_update BEFORE UPDATE ON tb_seller_orders FOR EACH ROW EXECUTE FUNCTION fn_set_last_update();
CREATE TRIGGER trg_tb_user_addresses_set_last_update BEFORE UPDATE ON tb_user_addresses FOR EACH ROW EXECUTE FUNCTION fn_set_last_update();
CREATE TRIGGER trg_tb_users_set_last_update BEFORE UPDATE ON tb_users FOR EACH ROW EXECUTE FUNCTION fn_set_last_update();
CREATE TRIGGER trg_tbb_orders_set_last_update BEFORE UPDATE ON tbb_orders FOR EACH ROW EXECUTE FUNCTION fn_set_last_update();
CREATE TRIGGER trg_tbc_categories_set_last_update BEFORE UPDATE ON tbc_categories FOR EACH ROW EXECUTE FUNCTION fn_set_last_update();
CREATE TRIGGER trg_tbc_payment_methods_set_last_update BEFORE UPDATE ON tbc_payment_methods FOR EACH ROW EXECUTE FUNCTION fn_set_last_update();
CREATE TRIGGER trg_tbc_payment_methods_types_set_last_update BEFORE UPDATE ON tbc_payment_methods_types FOR EACH ROW EXECUTE FUNCTION fn_set_last_update();
CREATE TRIGGER trg_tbd_address_components_set_last_update BEFORE UPDATE ON tbd_address_components FOR EACH ROW EXECUTE FUNCTION fn_set_last_update();
CREATE TRIGGER trg_tbd_order_details_set_last_update BEFORE UPDATE ON tbd_order_details FOR EACH ROW EXECUTE FUNCTION fn_set_last_update();
CREATE TRIGGER trg_tbd_payments_set_last_update BEFORE UPDATE ON tbd_payments FOR EACH ROW EXECUTE FUNCTION fn_set_last_update();
CREATE TRIGGER trg_tbd_products_categories_set_last_update BEFORE UPDATE ON tbd_products_categories FOR EACH ROW EXECUTE FUNCTION fn_set_last_update();
CREATE TRIGGER trg_tbd_shopping_cart_set_last_update BEFORE UPDATE ON tbd_shopping_cart FOR EACH ROW EXECUTE FUNCTION fn_set_last_update();
CREATE TRIGGER trg_tbd_user_payment_methods_set_last_update BEFORE UPDATE ON tbd_user_payment_methods FOR EACH ROW EXECUTE FUNCTION fn_set_last_update();
CREATE TRIGGER trg_tbd_users_offer_products_set_last_update BEFORE UPDATE ON tbd_users_offer_products FOR EACH ROW EXECUTE FUNCTION fn_set_last_update();
CREATE TRIGGER trg_tbd_users_wishlist_proudcts_set_last_update BEFORE UPDATE ON tbd_users_wishlist_proudcts FOR EACH ROW EXECUTE FUNCTION fn_set_last_update();

-- ---------- Triggers: bitácora en tb_logs ----------
CREATE TRIGGER trg_tb_carts_after_insert AFTER INSERT ON tb_carts FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Carrito','id');
CREATE TRIGGER trg_tb_carts_after_update AFTER UPDATE ON tb_carts FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Carrito','id');
CREATE TRIGGER trg_tb_carts_after_delete AFTER DELETE ON tb_carts FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Carrito','id');
CREATE TRIGGER trg_tb_people_after_insert AFTER INSERT ON tb_people FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Persona','person_id');
CREATE TRIGGER trg_tb_people_after_update AFTER UPDATE ON tb_people FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Persona','person_id');
CREATE TRIGGER trg_tb_people_after_delete AFTER DELETE ON tb_people FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Persona','person_id');
CREATE TRIGGER trg_tb_products_after_insert AFTER INSERT ON tb_products FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Producto','id');
CREATE TRIGGER trg_tb_products_after_update AFTER UPDATE ON tb_products FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Producto','id');
CREATE TRIGGER trg_tb_products_after_delete AFTER DELETE ON tb_products FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Producto','id');
CREATE TRIGGER trg_tb_seller_orders_after_insert AFTER INSERT ON tb_seller_orders FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Orden de vendedor','id');
CREATE TRIGGER trg_tb_seller_orders_after_update AFTER UPDATE ON tb_seller_orders FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Orden de vendedor','id');
CREATE TRIGGER trg_tb_seller_orders_after_delete AFTER DELETE ON tb_seller_orders FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Orden de vendedor','id');
CREATE TRIGGER trg_tb_user_addresses_after_insert AFTER INSERT ON tb_user_addresses FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Dirección de usuario','id');
CREATE TRIGGER trg_tb_user_addresses_after_update AFTER UPDATE ON tb_user_addresses FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Dirección de usuario','id');
CREATE TRIGGER trg_tb_user_addresses_after_delete AFTER DELETE ON tb_user_addresses FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Dirección de usuario','id');
CREATE TRIGGER trg_tb_users_after_insert AFTER INSERT ON tb_users FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Usuario','id');
CREATE TRIGGER trg_tb_users_after_update AFTER UPDATE ON tb_users FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Usuario','id');
CREATE TRIGGER trg_tb_users_after_delete AFTER DELETE ON tb_users FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Usuario','id');
CREATE TRIGGER trg_tbb_orders_after_insert AFTER INSERT ON tbb_orders FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Orden','id');
CREATE TRIGGER trg_tbb_orders_after_update AFTER UPDATE ON tbb_orders FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Orden','id');
CREATE TRIGGER trg_tbb_orders_after_delete AFTER DELETE ON tbb_orders FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Orden','id');
CREATE TRIGGER trg_tbc_categories_after_insert AFTER INSERT ON tbc_categories FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Categoría','id');
CREATE TRIGGER trg_tbc_categories_after_update AFTER UPDATE ON tbc_categories FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Categoría','id');
CREATE TRIGGER trg_tbc_categories_after_delete AFTER DELETE ON tbc_categories FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Categoría','id');
CREATE TRIGGER trg_tbc_payment_methods_after_insert AFTER INSERT ON tbc_payment_methods FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Método de pago','payment_method_id');
CREATE TRIGGER trg_tbc_payment_methods_after_update AFTER UPDATE ON tbc_payment_methods FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Método de pago','payment_method_id');
CREATE TRIGGER trg_tbc_payment_methods_after_delete AFTER DELETE ON tbc_payment_methods FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Método de pago','payment_method_id');
CREATE TRIGGER trg_tbc_payment_methods_types_after_insert AFTER INSERT ON tbc_payment_methods_types FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Tipo de método de pago','id');
CREATE TRIGGER trg_tbc_payment_methods_types_after_update AFTER UPDATE ON tbc_payment_methods_types FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Tipo de método de pago','id');
CREATE TRIGGER trg_tbc_payment_methods_types_after_delete AFTER DELETE ON tbc_payment_methods_types FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Tipo de método de pago','id');
CREATE TRIGGER trg_tbd_address_components_after_insert AFTER INSERT ON tbd_address_components FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Componente de dirección','id');
CREATE TRIGGER trg_tbd_address_components_after_update AFTER UPDATE ON tbd_address_components FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Componente de dirección','id');
CREATE TRIGGER trg_tbd_address_components_after_delete AFTER DELETE ON tbd_address_components FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Componente de dirección','id');
CREATE TRIGGER trg_tbd_order_details_after_insert AFTER INSERT ON tbd_order_details FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Detalle de orden','order_detail_id');
CREATE TRIGGER trg_tbd_order_details_after_update AFTER UPDATE ON tbd_order_details FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Detalle de orden','order_detail_id');
CREATE TRIGGER trg_tbd_order_details_after_delete AFTER DELETE ON tbd_order_details FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Detalle de orden','order_detail_id');
CREATE TRIGGER trg_tbd_order_items_after_insert AFTER INSERT ON tbd_order_items FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Ítem de orden de vendedor','id');
CREATE TRIGGER trg_tbd_order_items_after_update AFTER UPDATE ON tbd_order_items FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Ítem de orden de vendedor','id');
CREATE TRIGGER trg_tbd_order_items_after_delete AFTER DELETE ON tbd_order_items FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Ítem de orden de vendedor','id');
CREATE TRIGGER trg_tbd_payments_after_insert AFTER INSERT ON tbd_payments FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Pago','payment_id');
CREATE TRIGGER trg_tbd_payments_after_update AFTER UPDATE ON tbd_payments FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Pago','payment_id');
CREATE TRIGGER trg_tbd_payments_after_delete AFTER DELETE ON tbd_payments FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Pago','payment_id');
CREATE TRIGGER trg_tbd_products_categories_after_insert AFTER INSERT ON tbd_products_categories FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Relación producto-categoría','category_id,product_id');
CREATE TRIGGER trg_tbd_products_categories_after_update AFTER UPDATE ON tbd_products_categories FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Relación producto-categoría','category_id,product_id');
CREATE TRIGGER trg_tbd_products_categories_after_delete AFTER DELETE ON tbd_products_categories FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Relación producto-categoría','category_id,product_id');
CREATE TRIGGER trg_tbd_shopping_cart_after_insert AFTER INSERT ON tbd_shopping_cart FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Ítem de carrito','cart_item_id');
CREATE TRIGGER trg_tbd_shopping_cart_after_update AFTER UPDATE ON tbd_shopping_cart FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Ítem de carrito','cart_item_id');
CREATE TRIGGER trg_tbd_shopping_cart_after_delete AFTER DELETE ON tbd_shopping_cart FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Ítem de carrito','cart_item_id');
CREATE TRIGGER trg_tbd_user_payment_methods_after_insert AFTER INSERT ON tbd_user_payment_methods FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Método de pago de usuario','id');
CREATE TRIGGER trg_tbd_user_payment_methods_after_update AFTER UPDATE ON tbd_user_payment_methods FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Método de pago de usuario','id');
CREATE TRIGGER trg_tbd_user_payment_methods_after_delete AFTER DELETE ON tbd_user_payment_methods FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Método de pago de usuario','id');
CREATE TRIGGER trg_tbd_users_offer_products_after_insert AFTER INSERT ON tbd_users_offer_products FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Oferta de producto','product_offer_id');
CREATE TRIGGER trg_tbd_users_offer_products_after_update AFTER UPDATE ON tbd_users_offer_products FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Oferta de producto','product_offer_id');
CREATE TRIGGER trg_tbd_users_offer_products_after_delete AFTER DELETE ON tbd_users_offer_products FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Oferta de producto','product_offer_id');
CREATE TRIGGER trg_tbd_users_wishlist_proudcts_after_insert AFTER INSERT ON tbd_users_wishlist_proudcts FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Producto en lista de deseos','user_id,product_id');
CREATE TRIGGER trg_tbd_users_wishlist_proudcts_after_update AFTER UPDATE ON tbd_users_wishlist_proudcts FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Producto en lista de deseos','user_id,product_id');
CREATE TRIGGER trg_tbd_users_wishlist_proudcts_after_delete AFTER DELETE ON tbd_users_wishlist_proudcts FOR EACH ROW EXECUTE FUNCTION fn_log_cambios('Producto en lista de deseos','user_id,product_id');

-- ---------- Procedimientos almacenados ----------

-- Registro de usuario: separa la información entre tb_users y tb_people (contraseña con MD5, como en el original).
-- Uso: CALL sp_register_user('a@b.com','nick','Clave1234','Sr','Ana','Pérez','1999-01-31','Femenino','MX','5512345678', NULL, NULL);
CREATE OR REPLACE PROCEDURE sp_register_user(
    p_email             varchar,
    p_nickname          varchar,
    p_password          varchar,
    p_courtesy_title_id varchar,
    p_given_names       varchar,
    p_family_names      varchar,
    p_birth_date        date,
    p_gender            gender_t,
    p_country_code      varchar,
    p_phone             varchar,
    INOUT p_user_id     integer DEFAULT NULL,
    INOUT p_person_id   bigint  DEFAULT NULL
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_email    text      := lower(trim(p_email));
    v_nickname text      := trim(p_nickname);
    v_gender   gender_t  := COALESCE(p_gender, 'Prefiero no decirlo');
BEGIN
    -- Validaciones de cuenta
    IF v_email IS NULL OR v_email = '' THEN
        RAISE EXCEPTION 'El correo electrónico es obligatorio.' USING ERRCODE = '45000';
    END IF;
    IF v_email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        RAISE EXCEPTION 'El correo electrónico no tiene un formato válido.' USING ERRCODE = '45000';
    END IF;
    IF v_nickname IS NULL OR v_nickname = '' THEN
        RAISE EXCEPTION 'El nickname es obligatorio.' USING ERRCODE = '45000';
    END IF;
    IF p_password IS NULL OR char_length(p_password) < 8 THEN
        RAISE EXCEPTION 'La contraseña debe tener al menos 8 caracteres.' USING ERRCODE = '45000';
    END IF;

    -- Validaciones personales
    IF p_given_names IS NULL OR trim(p_given_names) = '' THEN
        RAISE EXCEPTION 'El nombre es obligatorio.' USING ERRCODE = '45000';
    END IF;
    IF p_family_names IS NULL OR trim(p_family_names) = '' THEN
        RAISE EXCEPTION 'Los apellidos son obligatorios.' USING ERRCODE = '45000';
    END IF;
    IF p_birth_date IS NOT NULL AND p_birth_date > CURRENT_DATE THEN
        RAISE EXCEPTION 'La fecha de nacimiento no puede ser futura.' USING ERRCODE = '45000';
    END IF;

    -- Duplicados
    IF EXISTS (SELECT 1 FROM tb_users WHERE email = v_email) THEN
        RAISE EXCEPTION 'El correo electrónico ya está registrado.' USING ERRCODE = '45000';
    END IF;
    IF EXISTS (SELECT 1 FROM tb_users WHERE nickname = v_nickname) THEN
        RAISE EXCEPTION 'El nickname ya está en uso.' USING ERRCODE = '45000';
    END IF;

    -- Registro (si algo falla, PostgreSQL revierte toda la llamada)
    INSERT INTO tb_users (email, nickname, password)
    VALUES (v_email, v_nickname, md5(p_password))
    RETURNING id INTO p_user_id;

    INSERT INTO tb_people (user_id, courtesy_title_id, given_names, family_names, birth_date, gender, country_code, phone)
    VALUES (p_user_id,
            NULLIF(trim(p_courtesy_title_id), ''),
            trim(p_given_names),
            trim(p_family_names),
            p_birth_date,
            v_gender,
            NULLIF(upper(trim(p_country_code)), ''),
            NULLIF(trim(p_phone), ''))
    RETURNING person_id INTO p_person_id;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_restore_product(p_id integer)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    UPDATE tb_products SET status = true WHERE id = p_id AND status = false;
$$;

CREATE OR REPLACE PROCEDURE sp_soft_delete_category(p_id integer)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    UPDATE tbc_categories SET status = false WHERE id = p_id AND status = true;
$$;

CREATE OR REPLACE PROCEDURE sp_soft_delete_product(p_id integer)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    UPDATE tb_products SET status = false WHERE id = p_id AND status = true;
$$;

CREATE OR REPLACE PROCEDURE sp_soft_delete_product_category(p_category_id integer, p_product_id integer)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    UPDATE tbd_products_categories SET status = false
     WHERE category_id = p_category_id AND product_id = p_product_id AND status = true;
$$;

-- Baja lógica de usuario. Solo para usuarios miembros de los roles superadmin, admin o support.
-- En PostgreSQL un procedimiento no devuelve filas, por eso este es una FUNCIÓN: SELECT * FROM sp_soft_delete_user(5);
CREATE OR REPLACE FUNCTION sp_soft_delete_user(p_user_id integer)
RETURNS TABLE (mensaje text, user_id integer, ejecutado_por text, estado_actual text, fecha_operacion timestamp)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_db_user  text := session_user::text;
    v_has_role boolean;
    v_exists   integer;
    v_status   integer;
    v_affected integer;
BEGIN
    SELECT EXISTS (
        SELECT 1
          FROM pg_auth_members m
          JOIN pg_roles r ON r.oid = m.roleid
          JOIN pg_roles u ON u.oid = m.member
         WHERE u.rolname = v_db_user
           AND r.rolname IN ('superadmin','admin','support')
    ) INTO v_has_role;

    IF NOT v_has_role THEN
        RAISE EXCEPTION 'Acceso denegado: rol no autorizado' USING ERRCODE = '45000';
    END IF;

    IF p_user_id IS NULL OR p_user_id = 0 THEN
        RAISE EXCEPTION 'El identificador del usuario es inválido' USING ERRCODE = '45000';
    END IF;

    SELECT count(*), max(u.status::int) INTO v_exists, v_status
      FROM tb_users u WHERE u.id = p_user_id;

    IF v_exists = 0 THEN
        RAISE EXCEPTION 'El usuario especificado no existe' USING ERRCODE = '45000';
    END IF;
    IF v_status = 0 THEN
        RAISE EXCEPTION 'El usuario ya se encuentra inactivo' USING ERRCODE = '45000';
    END IF;
    IF v_status IS NULL THEN
        RAISE EXCEPTION 'El usuario tiene un estado inválido' USING ERRCODE = '45000';
    END IF;

    UPDATE tb_users u SET status = false WHERE u.id = p_user_id AND u.status = true;
    GET DIAGNOSTICS v_affected = ROW_COUNT;

    IF v_affected <> 1 THEN
        RAISE EXCEPTION 'No se pudo desactivar el usuario' USING ERRCODE = '45000';
    END IF;

    RETURN QUERY SELECT 'Usuario desactivado correctamente'::text, p_user_id, v_db_user,
                        'Inactivo'::text, CURRENT_TIMESTAMP::timestamp;
END;
$$;

-- Como en MySQL, solo quien reciba permiso explícito debe poder ejecutarlos.
REVOKE ALL ON PROCEDURE sp_register_user(varchar,varchar,varchar,varchar,varchar,varchar,date,gender_t,varchar,varchar,integer,bigint) FROM PUBLIC;
REVOKE ALL ON PROCEDURE sp_restore_product(integer) FROM PUBLIC;
REVOKE ALL ON PROCEDURE sp_soft_delete_category(integer) FROM PUBLIC;
REVOKE ALL ON PROCEDURE sp_soft_delete_product(integer) FROM PUBLIC;
REVOKE ALL ON PROCEDURE sp_soft_delete_product_category(integer,integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION  sp_soft_delete_user(integer) FROM PUBLIC;

-- ---------- Vistas de trazabilidad ----------
CREATE OR REPLACE VIEW vw_trazabilidad_carrito_compras AS
SELECT b.id               AS log_id,
       b.table_name       AS table_name,
       b.operation        AS operacion,
       b.db_user          AS usuario_bd,
       COALESCE((SELECT string_agg(DISTINCT r.rolname::text, ', ' ORDER BY r.rolname::text)
                   FROM pg_auth_members m
                   JOIN pg_roles r ON r.oid = m.roleid
                   JOIN pg_roles u ON u.oid = m.member
                  WHERE u.rolname = split_part(b.db_user, '@', 1)),
                'Sin rol asignado') AS roles,
       b.description      AS detalle,
       b.operation_date   AS operation_date,
       b.operation_status AS estado_operacion
  FROM tb_logs b
 WHERE b.table_name = 'tbd_shopping_cart';

CREATE OR REPLACE VIEW vw_trazabilidad_carritos AS
SELECT b.id               AS log_id,
       b.table_name       AS table_name,
       b.operation        AS operacion,
       b.db_user          AS usuario_bd,
       COALESCE((SELECT string_agg(DISTINCT r.rolname::text, ', ' ORDER BY r.rolname::text)
                   FROM pg_auth_members m
                   JOIN pg_roles r ON r.oid = m.roleid
                   JOIN pg_roles u ON u.oid = m.member
                  WHERE u.rolname = split_part(b.db_user, '@', 1)),
                'Sin rol asignado') AS roles,
       b.description      AS detalle,
       b.operation_date   AS operation_date,
       b.operation_status AS estado_operacion
  FROM tb_logs b
 WHERE b.table_name = 'tb_carts';

CREATE OR REPLACE VIEW vw_trazabilidad_categorias AS
SELECT b.id               AS log_id,
       b.table_name       AS table_name,
       b.operation        AS operacion,
       b.db_user          AS usuario_bd,
       COALESCE((SELECT string_agg(DISTINCT r.rolname::text, ', ' ORDER BY r.rolname::text)
                   FROM pg_auth_members m
                   JOIN pg_roles r ON r.oid = m.roleid
                   JOIN pg_roles u ON u.oid = m.member
                  WHERE u.rolname = split_part(b.db_user, '@', 1)),
                'Sin rol asignado') AS roles,
       b.description      AS detalle,
       b.operation_date   AS operation_date,
       b.operation_status AS estado_operacion
  FROM tb_logs b
 WHERE b.table_name = 'tbc_categories';

CREATE OR REPLACE VIEW vw_trazabilidad_componentes_direccion AS
SELECT b.id               AS log_id,
       b.table_name       AS table_name,
       b.operation        AS operacion,
       b.db_user          AS usuario_bd,
       COALESCE((SELECT string_agg(DISTINCT r.rolname::text, ', ' ORDER BY r.rolname::text)
                   FROM pg_auth_members m
                   JOIN pg_roles r ON r.oid = m.roleid
                   JOIN pg_roles u ON u.oid = m.member
                  WHERE u.rolname = split_part(b.db_user, '@', 1)),
                'Sin rol asignado') AS roles,
       b.description      AS detalle,
       b.operation_date   AS operation_date,
       b.operation_status AS estado_operacion
  FROM tb_logs b
 WHERE b.table_name = 'tbd_address_components';

CREATE OR REPLACE VIEW vw_trazabilidad_detalle_ordenes AS
SELECT b.id               AS log_id,
       b.table_name       AS table_name,
       b.operation        AS operacion,
       b.db_user          AS usuario_bd,
       COALESCE((SELECT string_agg(DISTINCT r.rolname::text, ', ' ORDER BY r.rolname::text)
                   FROM pg_auth_members m
                   JOIN pg_roles r ON r.oid = m.roleid
                   JOIN pg_roles u ON u.oid = m.member
                  WHERE u.rolname = split_part(b.db_user, '@', 1)),
                'Sin rol asignado') AS roles,
       b.description      AS detalle,
       b.operation_date   AS operation_date,
       b.operation_status AS estado_operacion
  FROM tb_logs b
 WHERE b.table_name = 'tbd_order_details';

CREATE OR REPLACE VIEW vw_trazabilidad_direcciones_usuario AS
SELECT b.id               AS log_id,
       b.table_name       AS table_name,
       b.operation        AS operacion,
       b.db_user          AS usuario_bd,
       COALESCE((SELECT string_agg(DISTINCT r.rolname::text, ', ' ORDER BY r.rolname::text)
                   FROM pg_auth_members m
                   JOIN pg_roles r ON r.oid = m.roleid
                   JOIN pg_roles u ON u.oid = m.member
                  WHERE u.rolname = split_part(b.db_user, '@', 1)),
                'Sin rol asignado') AS roles,
       b.description      AS detalle,
       b.operation_date   AS operation_date,
       b.operation_status AS estado_operacion
  FROM tb_logs b
 WHERE b.table_name = 'tb_user_addresses';

CREATE OR REPLACE VIEW vw_trazabilidad_items_orden_vendedor AS
SELECT b.id               AS log_id,
       b.table_name       AS table_name,
       b.operation        AS operacion,
       b.db_user          AS usuario_bd,
       COALESCE((SELECT string_agg(DISTINCT r.rolname::text, ', ' ORDER BY r.rolname::text)
                   FROM pg_auth_members m
                   JOIN pg_roles r ON r.oid = m.roleid
                   JOIN pg_roles u ON u.oid = m.member
                  WHERE u.rolname = split_part(b.db_user, '@', 1)),
                'Sin rol asignado') AS roles,
       b.description      AS detalle,
       b.operation_date   AS operation_date,
       b.operation_status AS estado_operacion
  FROM tb_logs b
 WHERE b.table_name = 'tbd_order_items';

CREATE OR REPLACE VIEW vw_trazabilidad_lista_deseos AS
SELECT b.id               AS log_id,
       b.table_name       AS table_name,
       b.operation        AS operacion,
       b.db_user          AS usuario_bd,
       COALESCE((SELECT string_agg(DISTINCT r.rolname::text, ', ' ORDER BY r.rolname::text)
                   FROM pg_auth_members m
                   JOIN pg_roles r ON r.oid = m.roleid
                   JOIN pg_roles u ON u.oid = m.member
                  WHERE u.rolname = split_part(b.db_user, '@', 1)),
                'Sin rol asignado') AS roles,
       b.description      AS detalle,
       b.operation_date   AS operation_date,
       b.operation_status AS estado_operacion
  FROM tb_logs b
 WHERE b.table_name = 'tbd_users_wishlist_proudcts';

CREATE OR REPLACE VIEW vw_trazabilidad_metodos_pago AS
SELECT b.id               AS log_id,
       b.table_name       AS table_name,
       b.operation        AS operacion,
       b.db_user          AS usuario_bd,
       COALESCE((SELECT string_agg(DISTINCT r.rolname::text, ', ' ORDER BY r.rolname::text)
                   FROM pg_auth_members m
                   JOIN pg_roles r ON r.oid = m.roleid
                   JOIN pg_roles u ON u.oid = m.member
                  WHERE u.rolname = split_part(b.db_user, '@', 1)),
                'Sin rol asignado') AS roles,
       b.description      AS detalle,
       b.operation_date   AS operation_date,
       b.operation_status AS estado_operacion
  FROM tb_logs b
 WHERE b.table_name = 'tbc_payment_methods';

CREATE OR REPLACE VIEW vw_trazabilidad_metodos_pago_usuario AS
SELECT b.id               AS log_id,
       b.table_name       AS table_name,
       b.operation        AS operacion,
       b.db_user          AS usuario_bd,
       COALESCE((SELECT string_agg(DISTINCT r.rolname::text, ', ' ORDER BY r.rolname::text)
                   FROM pg_auth_members m
                   JOIN pg_roles r ON r.oid = m.roleid
                   JOIN pg_roles u ON u.oid = m.member
                  WHERE u.rolname = split_part(b.db_user, '@', 1)),
                'Sin rol asignado') AS roles,
       b.description      AS detalle,
       b.operation_date   AS operation_date,
       b.operation_status AS estado_operacion
  FROM tb_logs b
 WHERE b.table_name = 'tbd_user_payment_methods';

CREATE OR REPLACE VIEW vw_trazabilidad_ordenes AS
SELECT b.id               AS log_id,
       b.table_name       AS table_name,
       b.operation        AS operacion,
       b.db_user          AS usuario_bd,
       COALESCE((SELECT string_agg(DISTINCT r.rolname::text, ', ' ORDER BY r.rolname::text)
                   FROM pg_auth_members m
                   JOIN pg_roles r ON r.oid = m.roleid
                   JOIN pg_roles u ON u.oid = m.member
                  WHERE u.rolname = split_part(b.db_user, '@', 1)),
                'Sin rol asignado') AS roles,
       b.description      AS detalle,
       b.operation_date   AS operation_date,
       b.operation_status AS estado_operacion
  FROM tb_logs b
 WHERE b.table_name = 'tbb_orders';

CREATE OR REPLACE VIEW vw_trazabilidad_ordenes_vendedor AS
SELECT b.id               AS log_id,
       b.table_name       AS table_name,
       b.operation        AS operacion,
       b.db_user          AS usuario_bd,
       COALESCE((SELECT string_agg(DISTINCT r.rolname::text, ', ' ORDER BY r.rolname::text)
                   FROM pg_auth_members m
                   JOIN pg_roles r ON r.oid = m.roleid
                   JOIN pg_roles u ON u.oid = m.member
                  WHERE u.rolname = split_part(b.db_user, '@', 1)),
                'Sin rol asignado') AS roles,
       b.description      AS detalle,
       b.operation_date   AS operation_date,
       b.operation_status AS estado_operacion
  FROM tb_logs b
 WHERE b.table_name = 'tb_seller_orders';

CREATE OR REPLACE VIEW vw_trazabilidad_pagos AS
SELECT b.id               AS log_id,
       b.table_name       AS table_name,
       b.operation        AS operacion,
       b.db_user          AS usuario_bd,
       COALESCE((SELECT string_agg(DISTINCT r.rolname::text, ', ' ORDER BY r.rolname::text)
                   FROM pg_auth_members m
                   JOIN pg_roles r ON r.oid = m.roleid
                   JOIN pg_roles u ON u.oid = m.member
                  WHERE u.rolname = split_part(b.db_user, '@', 1)),
                'Sin rol asignado') AS roles,
       b.description      AS detalle,
       b.operation_date   AS operation_date,
       b.operation_status AS estado_operacion
  FROM tb_logs b
 WHERE b.table_name = 'tbd_payments';

CREATE OR REPLACE VIEW vw_trazabilidad_personas AS
SELECT b.id               AS log_id,
       b.table_name       AS table_name,
       b.operation        AS operacion,
       b.db_user          AS usuario_bd,
       COALESCE((SELECT string_agg(DISTINCT r.rolname::text, ', ' ORDER BY r.rolname::text)
                   FROM pg_auth_members m
                   JOIN pg_roles r ON r.oid = m.roleid
                   JOIN pg_roles u ON u.oid = m.member
                  WHERE u.rolname = split_part(b.db_user, '@', 1)),
                'Sin rol asignado') AS roles,
       b.description      AS detalle,
       b.operation_date   AS operation_date,
       b.operation_status AS estado_operacion
  FROM tb_logs b
 WHERE b.table_name = 'tb_people';

CREATE OR REPLACE VIEW vw_trazabilidad_productos AS
SELECT b.id               AS log_id,
       b.table_name       AS table_name,
       b.operation        AS operacion,
       b.db_user          AS usuario_bd,
       COALESCE((SELECT string_agg(DISTINCT r.rolname::text, ', ' ORDER BY r.rolname::text)
                   FROM pg_auth_members m
                   JOIN pg_roles r ON r.oid = m.roleid
                   JOIN pg_roles u ON u.oid = m.member
                  WHERE u.rolname = split_part(b.db_user, '@', 1)),
                'Sin rol asignado') AS roles,
       b.description      AS detalle,
       b.operation_date   AS operation_date,
       b.operation_status AS estado_operacion
  FROM tb_logs b
 WHERE b.table_name = 'tb_products';

CREATE OR REPLACE VIEW vw_trazabilidad_productos_categorias AS
SELECT b.id               AS log_id,
       b.table_name       AS table_name,
       b.operation        AS operacion,
       b.db_user          AS usuario_bd,
       COALESCE((SELECT string_agg(DISTINCT r.rolname::text, ', ' ORDER BY r.rolname::text)
                   FROM pg_auth_members m
                   JOIN pg_roles r ON r.oid = m.roleid
                   JOIN pg_roles u ON u.oid = m.member
                  WHERE u.rolname = split_part(b.db_user, '@', 1)),
                'Sin rol asignado') AS roles,
       b.description      AS detalle,
       b.operation_date   AS operation_date,
       b.operation_status AS estado_operacion
  FROM tb_logs b
 WHERE b.table_name = 'tbd_products_categories';

CREATE OR REPLACE VIEW vw_trazabilidad_tipos_metodos_pago AS
SELECT b.id               AS log_id,
       b.table_name       AS table_name,
       b.operation        AS operacion,
       b.db_user          AS usuario_bd,
       COALESCE((SELECT string_agg(DISTINCT r.rolname::text, ', ' ORDER BY r.rolname::text)
                   FROM pg_auth_members m
                   JOIN pg_roles r ON r.oid = m.roleid
                   JOIN pg_roles u ON u.oid = m.member
                  WHERE u.rolname = split_part(b.db_user, '@', 1)),
                'Sin rol asignado') AS roles,
       b.description      AS detalle,
       b.operation_date   AS operation_date,
       b.operation_status AS estado_operacion
  FROM tb_logs b
 WHERE b.table_name = 'tbc_payment_methods_types';

CREATE OR REPLACE VIEW vw_trazabilidad_users_offer_products AS
SELECT b.id               AS log_id,
       b.table_name       AS table_name,
       b.operation        AS operacion,
       b.db_user          AS usuario_bd,
       COALESCE((SELECT string_agg(DISTINCT r.rolname::text, ', ' ORDER BY r.rolname::text)
                   FROM pg_auth_members m
                   JOIN pg_roles r ON r.oid = m.roleid
                   JOIN pg_roles u ON u.oid = m.member
                  WHERE u.rolname = split_part(b.db_user, '@', 1)),
                'Sin rol asignado') AS roles,
       b.description      AS detalle,
       b.operation_date   AS operation_date,
       b.operation_status AS estado_operacion
  FROM tb_logs b
 WHERE b.table_name = 'tbd_users_offer_products';

CREATE OR REPLACE VIEW vw_trazabilidad_usuarios AS
SELECT b.id               AS log_id,
       b.table_name       AS table_name,
       b.operation        AS operacion,
       b.db_user          AS usuario_bd,
       COALESCE((SELECT string_agg(DISTINCT r.rolname::text, ', ' ORDER BY r.rolname::text)
                   FROM pg_auth_members m
                   JOIN pg_roles r ON r.oid = m.roleid
                   JOIN pg_roles u ON u.oid = m.member
                  WHERE u.rolname = split_part(b.db_user, '@', 1)),
                'Sin rol asignado') AS roles,
       b.description      AS detalle,
       b.operation_date   AS operation_date,
       b.operation_status AS estado_operacion
  FROM tb_logs b
 WHERE b.table_name = 'tb_users';

