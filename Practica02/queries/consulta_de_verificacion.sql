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