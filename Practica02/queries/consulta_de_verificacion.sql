use db_test;

/* Verificar el total de tablas en mi base de datos*/
SHOW TABLES;

/* Verificar el total de triggers en mi base de datos*/
SHOW TRIGGERS FROM db_test;

/*Consultar los registros de los usuarios*/
SELECT * FROM tb_users;

/*Consultar los registros de la bitacora*/
SELECT * FROM tb_logs;
/* Verifica los usuarios remotos creados en el servidor */
SELECT user,host FROM mysql.user WHERE host="%";

/* verificar los roles asignados a los usuarios remotos creados en el servidor*/
SELECT
    FROM_USER AS rol,
    FROM_HOST AS Host_Rol,
    TO_USER AS Usuario,
    TO_HOST AS Host_Usuario
    from mysql.role_edges
    order by FROM_USER, TO_USER;

SELECT      
    u.nickname,
    u.email,     
    b.db_user AS inserted_by,     
    GROUP_CONCAT(DISTINCT re.FROM_USER ORDER BY re.FROM_USER SEPARATOR ',') AS roles,          
    b.description AS operation_description, -- Corregido: 'description'         
    b.operation_date  
FROM tb_users u  
JOIN tb_logs b         
    ON b.description LIKE CONCAT('%', u.nickname, '%') -- Corregido: 'description' y 'nickname'
    AND b.description LIKE CONCAT('%', u.email, '%')  
LEFT JOIN mysql.role_edges re         
    ON re.TO_USER = SUBSTRING_INDEX(b.db_user, '@', 1)  
WHERE b.operation = 'Create' -- Corregido: 'operation' en vez de 'table_operation'
  AND b.table_name = 'tb_users'  
GROUP BY 
    u.nickname, 
    u.email, 
    b.db_user, 
    b.description, 
    b.operation_date 
ORDER BY b.operation_date ASC  
LIMIT 0, 1000;

SELECT User, Host FROM mysql.user WHERE Host = '%' AND account_locked = 'Y';

SELECT User, Host FROM mysql.user WHERE Host = '%' AND account_locked = 'N';

SELECT  TO_USER AS usuario,  TO_HOST AS host, FROM_USER AS rol, FROM_HOST AS rol_host
FROM mysql.role_edges ORDER BY TO_USER, FROM_USER;

SELECT * FROM vw_trazabilidad_productos ORDER BY operation_date desc limit 10;

SELECT * FROM vw_trazabilidad_usuarios ORDER BY operation_date asc;