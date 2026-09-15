CREATE DATABASE  IF NOT EXISTS `db_test` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `db_test`;
-- MySQL dump 10.13  Distrib 8.0.36, for Win64 (x86_64)
--
-- Host: localhost    Database: db_test
-- ------------------------------------------------------
-- Server version	8.0.36

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `tb_logs`
--

DROP TABLE IF EXISTS `tb_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_logs` (
  `ID` int NOT NULL AUTO_INCREMENT,
  `table_name` varchar(100) NOT NULL,
  `operation` enum('Create','Read','Update','Delete') NOT NULL,
  `db_user` varchar(80) NOT NULL,
  `description` text NOT NULL,
  `operation_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `operation_status` bit(1) DEFAULT b'1',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tb_logs`
--

LOCK TABLES `tb_logs` WRITE;
/*!40000 ALTER TABLE `tb_logs` DISABLE KEYS */;
INSERT INTO `tb_logs` VALUES (1,'tb_users','Create','root@localhost','Usuario creado. ID=1, email=240221@utxicotepec.edu.mx, nickname= ING-CARLOS','2026-09-08 11:22:48',_binary ''),(2,'tb_users','Create','root@localhost','Usuario creado. ID=2, email=240628@utxicotepec.edu.mx, nickname= ING-jose','2026-09-08 11:23:09',_binary ''),(3,'tb_users','Create','root@localhost','Usuario creado. ID=3, email=240558@utxicotepec.edu.mx, nickname= ING-johny','2026-09-08 11:24:14',_binary ''),(4,'tb_users','Create','saul.barrios@PC-06','Usuario creado. ID=4, email=carlos@mail.com, nickname=solis','2026-09-09 17:19:03',_binary ''),(5,'tb_users','Create','saul.barrios@PC-06','Usuario creado. ID=5, email=erick@mail.com, nickname=erick','2026-09-09 17:20:31',_binary ''),(6,'tb_users','Create','saul.barrios@PC-06','Usuario creado. ID=6, email=pablo@mail.com, nickname=Pablo','2026-09-09 17:20:44',_binary ''),(7,'tb_users','Create','saul.barrios@PC-06','Usuario creado. ID=2, email=240628@utxicotepec.edu.mx, nickname=ING-jose','2026-09-09 17:51:39',_binary ''),(8,'tb_users','Update','saul.barrios@PC-06','Usuario actualizado. ID=6. Cambios: nickname: [Pablo] -> [PabloModificado]','2026-09-09 17:52:15',_binary ''),(9,'tb_users','Create','saul.barrios@PC-06','Usuario creado. ID=7, email=felipe@mail.com, nickname=Felipe','2026-09-09 18:07:44',_binary ''),(10,'tb_users','Update','saul.barrios@PC-06','Usuario actualizado. ID=6. Cambios: ','2026-09-09 18:08:24',_binary ''),(11,'tb_users','Delete','saul.barrios@PC-06','Usuario eliminado. ID=7, email=felipe@mail.com, nickname=Felipe','2026-09-09 18:08:35',_binary '');
/*!40000 ALTER TABLE `tb_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tb_users`
--

DROP TABLE IF EXISTS `tb_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_users` (
  `ID` int NOT NULL AUTO_INCREMENT,
  `email` varchar(80) NOT NULL,
  `nickname` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `creation_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_update` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `last_login` datetime DEFAULT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `email` (`email`),
  UNIQUE KEY `nickname` (`nickname`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tb_users`
--

LOCK TABLES `tb_users` WRITE;
/*!40000 ALTER TABLE `tb_users` DISABLE KEYS */;
INSERT INTO `tb_users` VALUES (1,'240221@utxicotepec.edu.mx','ING-CARLOS','52dcb810931e20f7aa2f49b3510d3805','2026-09-08 11:22:48','2026-09-09 17:41:47',NULL),(3,'240558@utxicotepec.edu.mx','ING-johny','52dcb810931e20f7aa2f49b3510d3805','2026-09-08 11:24:14','2026-09-09 17:41:47',NULL),(4,'carlos@mail.com','solis','52dcb810931e20f7aa2f49b3510d3805','2026-09-09 17:19:03','2026-09-09 17:41:47',NULL),(5,'erick@mail.com','erick','52dcb810931e20f7aa2f49b3510d3805','2026-09-09 17:20:31','2026-09-09 17:41:47',NULL),(6,'pablo@mail.com','PabloModificado','a7f15dadaafe4f037f9dace179b1767c','2026-09-09 17:20:44','2026-09-09 17:52:15',NULL);
/*!40000 ALTER TABLE `tb_users` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_users_after_insert` AFTER INSERT ON `tb_users` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (
        table_name,
        operation,
        db_user,
        description,
        operation_date,
        operation_status
    )
    VALUES (
        'tb_users',
        'Create',
        USER(),
        CONCAT(
            'Usuario creado. ID=', NEW.ID,
            ', email=', NEW.email,
            ', nickname=', NEW.nickname
        ),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_users_after_update` AFTER UPDATE ON `tb_users` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (
        table_name,
        operation,
        db_user,
        description,
        operation_date,
        operation_status
    )
    VALUES (
        'tb_users',
        'Update',
        USER(),
        CONCAT(
            'Usuario actualizado. ID=', NEW.ID,
            '. Cambios: ',
            CONCAT_WS(
                ', ',
                IF(
                    NOT (OLD.email <=> NEW.email),
                    CONCAT(
                        'email: [',
                        COALESCE(OLD.email, 'NULL'),
                        '] -> [',
                        COALESCE(NEW.email, 'NULL'),
                        ']'
                    ),
                    NULL
                ),
                IF(
                    NOT (OLD.nickname <=> NEW.nickname),
                    CONCAT(
                        'nickname: [',
                        COALESCE(OLD.nickname, 'NULL'),
                        '] -> [',
                        COALESCE(NEW.nickname, 'NULL'),
                        ']'
                    ),
                    NULL
                )
            )
        ),
        CURRENT_TIMESTAMP,
b'1'
);
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_users_after_delete` AFTER DELETE ON `tb_users` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (
        table_name,
        operation,
        db_user,
        description,
        operation_date,
        operation_status
    )
    VALUES (
        'tb_users',
        'Delete',
        USER(),
        CONCAT(
            'Usuario eliminado. ID=', OLD.ID,
            ', email=', COALESCE(OLD.email, 'NULL'),
            ', nickname=', COALESCE(OLD.nickname, 'NULL')
        ),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-09-09 18:11:53
