-- phpMyAdmin SQL Dump
-- version 5.0.4
-- https://www.phpmyadmin.net/
--
-- Hôte : 127.0.0.1
-- Généré le : lun. 22 mars 2021 à 02:02
-- Version du serveur :  10.4.11-MariaDB
-- Version de PHP : 8.0.0

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de données : `store`
--
CREATE DATABASE IF NOT EXISTS `store` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `store`;

DELIMITER $$
--
-- Procédures
--
DROP PROCEDURE IF EXISTS `insert_slot`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `insert_slot` (IN `d` DATE)  NO SQL
BEGIN
INSERT INTO timeslot (`slotDate`, `full`, `expired`) VALUES (@d, '0', '0');
END$$

DROP PROCEDURE IF EXISTS `timeslot_generation`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `timeslot_generation` (IN `date_limit` DATE)  NO SQL
BEGIN
  DECLARE done BOOLEAN DEFAULT FALSE;
  DECLARE vname TIME;
  DECLARE vdays VARCHAR(20);
  DECLARE dow CHARACTER;
  DECLARE day DATE DEFAULT CURRENT_DATE;
  DECLARE nd DATETIME;
  DECLARE curTime CURSOR FOR SELECT `name`,`days` FROM slot;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

  WHILE DATEDIFF(date_limit,day)>0 do

    OPEN curTime;
      read_loop: LOOP
        FETCH curTime INTO vname, vdays;
        IF done THEN
          LEAVE read_loop;
        END IF;
        SET dow=CONVERT(WEEKDAY(day)+1,CHARACTER);
        IF (LOCATE(dow,vdays) > 0) THEN
            SET nd=STR_TO_DATE(CONCAT(day, ' ', vname), '%Y-%m-%d %H:%i:%s');
            SELECT nd;
            INSERT IGNORE INTO timeslot (`slotDate`) VALUES (nd);
        END IF;
      END LOOP;
    CLOSE curTime;
    SET done=FALSE;
    SET day=DATE_ADD(day, INTERVAL 1 DAY);
  END WHILE;
END$$

DROP PROCEDURE IF EXISTS `updateOrderAmount`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateOrderAmount` (IN `id_Order` INT)  BEGIN
	update `order` set amount=(select sum(p.price*o.quantity) from orderdetail o inner JOIN product p on p.id=o.idProduct where o.idOrder=id_Order) where id=id_Order;
    	update `order` set toPay=(select sum(p.price*o.quantity) from orderdetail o inner JOIN product p on p.id=o.idProduct where o.idOrder=id_Order and o.prepared) where id=id_Order;
        update `order` set missingNumber=(select sum(o.quantity) from orderdetail o inner JOIN product p on p.id=o.idProduct where o.idOrder=id_Order and !o.prepared) where id=id_Order;
        update `order` set itemsNumber=(select sum(o.quantity) from orderdetail o inner JOIN product p on p.id=o.idProduct where o.idOrder=id_Order) where id=id_Order;
END$$

DROP PROCEDURE IF EXISTS `updateTimeSlot`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateTimeSlot` (IN `id_timeslot` INT)  NO SQL
update timeslot set `full`=isTimeslotFull(id_timeslot), `expired`=isTimeslotExpired(id_timeslot) where id=id_timeslot$$

--
-- Fonctions
--
DROP FUNCTION IF EXISTS `getFreeEmployee`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `getFreeEmployee` (`id_timeslot` INT) RETURNS INT(11) NO SQL
BEGIN
DECLARE res INT;

SET res=(SELECT e.id FROM employee e where e.id not in (select o.idEmployee from `order` o inner join timeslot t on o.idTimeslot=t.id where t.id=id_timeslot and o.idEmployee is not null) limit 1);
RETURN res;
END$$

DROP FUNCTION IF EXISTS `getPackPromo`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `getPackPromo` (`id_pack` INT) RETURNS FLOAT NO SQL
BEGIN
DECLARE old_p float;
DECLARE new_p float;

SET old_p=(SELECT SUM(p.price) FROM `pack` inner join product p on `pack`.idProduct=p.id WHERE idPack=id_pack);
SET new_p=(SELECT price from product where id=id_pack);
return new_p-old_p;
END$$

DROP FUNCTION IF EXISTS `isTimeslotExpired`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `isTimeslotExpired` (`id_timeslot` INT) RETURNS TINYINT(1) NO SQL
return (select (slotDate>=CURDATE()-0.5) from timeslot WHERE id=id_timeslot)$$

DROP FUNCTION IF EXISTS `isTimeslotFull`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `isTimeslotFull` (`id_timeslot` INT) RETURNS INT(11) NO SQL
return (SELECT count(*) FROM `order` WHERE idTimeslot=id_timeslot AND idEmployee is NULL)>=(SELECT COUNT(*) FROM employee e where e.id not in (select o.idEmployee from `order` o inner join timeslot t on o.idTimeslot=t.id where t.id=id_timeslot and o.idEmployee is not null))$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `associatedproduct`
--

DROP TABLE IF EXISTS `associatedproduct`;
CREATE TABLE `associatedproduct` (
  `idProduct` int(11) NOT NULL,
  `idAssoProduct` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Déchargement des données de la table `associatedproduct`
--

INSERT INTO `associatedproduct` (`idProduct`, `idAssoProduct`) VALUES
(1, 128),
(1, 130),
(4, 128),
(7, 129),
(11, 130),
(13, 130),
(16, 130),
(31, 129),
(32, 128),
(43, 130),
(73, 130);

-- --------------------------------------------------------

--
-- Structure de la table `basket`
--

DROP TABLE IF EXISTS `basket`;
CREATE TABLE `basket` (
  `id` int(11) NOT NULL,
  `name` varchar(60) NOT NULL,
  `dateCreation` timestamp NOT NULL DEFAULT current_timestamp(),
  `idUser` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Déchargement des données de la table `basket`
--

INSERT INTO `basket` (`id`, `name`, `dateCreation`, `idUser`) VALUES
(1, 'Mis de côté', '2021-03-05 11:37:45', 2),
(2, 'Mis de côté', '2021-03-06 02:23:11', 3);

-- --------------------------------------------------------

--
-- Structure de la table `basketdetail`
--

DROP TABLE IF EXISTS `basketdetail`;
CREATE TABLE `basketdetail` (
  `idBasket` int(11) NOT NULL,
  `idProduct` int(11) NOT NULL,
  `quantity` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Déchargement des données de la table `basketdetail`
--

INSERT INTO `basketdetail` (`idBasket`, `idProduct`, `quantity`) VALUES
(1, 1, 1),
(2, 6, 1);

-- --------------------------------------------------------

--
-- Structure de la table `employee`
--

DROP TABLE IF EXISTS `employee`;
CREATE TABLE `employee` (
  `id` int(11) NOT NULL,
  `name` varchar(60) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Déchargement des données de la table `employee`
--

INSERT INTO `employee` (`id`, `name`, `email`, `password`) VALUES
(1, 'Mario', 'mario@nintendo.org', '0000'),
(2, 'Luigi', 'luigi@nintendo.org', '0000'),
(3, 'Waluigi', 'Waluigi@nintendo.org', '0000');

-- --------------------------------------------------------

--
-- Structure de la table `order`
--

DROP TABLE IF EXISTS `order`;
CREATE TABLE `order` (
  `id` int(11) NOT NULL,
  `dateCreation` timestamp NOT NULL DEFAULT current_timestamp(),
  `idUser` int(11) NOT NULL,
  `idEmployee` int(11) DEFAULT NULL,
  `status` enum('created','prepared','delivered','') NOT NULL,
  `amount` decimal(6,2) NOT NULL,
  `toPay` decimal(6,2) NOT NULL,
  `itemsNumber` int(11) NOT NULL,
  `missingNumber` int(11) NOT NULL,
  `idTimeslot` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Déchargement des données de la table `order`
--

INSERT INTO `order` (`id`, `dateCreation`, `idUser`, `idEmployee`, `status`, `amount`, `toPay`, `itemsNumber`, `missingNumber`, `idTimeslot`) VALUES
(1, '2021-03-03 12:10:31', 1, 1, 'created', '95.70', '0.00', 1, 1, 1),
(3, '2021-03-03 18:44:16', 1, 2, 'created', '147.74', '0.00', 1, 1, 1),
(4, '2021-03-04 10:52:53', 1, 1, 'created', '99.21', '0.00', 1, 1, 2),
(8, '2021-03-04 11:05:50', 1, 2, 'created', '274.70', '0.00', 3, 3, 2),
(9, '2021-03-05 11:43:03', 2, 3, 'created', '118.94', '0.00', 1, 1, 2),
(13, '2021-03-06 14:12:42', 3, 1, 'created', '972.85', '0.00', 5, 5, 3),
(15, '2021-03-07 11:56:07', 3, 2, 'created', '1730.20', '0.00', 10, 10, 3);

--
-- Déclencheurs `order`
--
DROP TRIGGER IF EXISTS `after_insert_order`;
DELIMITER $$
CREATE TRIGGER `after_insert_order` AFTER INSERT ON `order` FOR EACH ROW if (NEW.idTimeslot is NOT NULL) THEN
    call updateTimeSlot(NEW.idTimeslot);
END IF
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `before_insert_order`;
DELIMITER $$
CREATE TRIGGER `before_insert_order` BEFORE INSERT ON `order` FOR EACH ROW BEGIN
IF (NEW.idEmployee IS NULL) THEN
    IF(NEW.idTimeslot IS NOT NULL) THEN
        SET NEW.idEmployee=getFreeEmployee(NEW.idTimeslot);
    END IF;
END IF;
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `delete_order`;
DELIMITER $$
CREATE TRIGGER `delete_order` AFTER DELETE ON `order` FOR EACH ROW if (OLD.idTimeslot is NOT NULL) THEN
    call updateTimeSlot(OLD.idTimeslot);
end if
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `update_order`;
DELIMITER $$
CREATE TRIGGER `update_order` AFTER UPDATE ON `order` FOR EACH ROW if (NEW.idTimeslot is NOT NULL) THEN
    call updateTimeSlot(NEW.idTimeslot);
ELSEIF(OLD.idTimeslot is NOT NULL) THEN
    call updateTimeSlot(OLD.idTimeslot);
end if
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `orderdetail`
--

DROP TABLE IF EXISTS `orderdetail`;
CREATE TABLE `orderdetail` (
  `idOrder` int(11) NOT NULL,
  `idProduct` int(11) NOT NULL,
  `quantity` decimal(6,2) NOT NULL,
  `prepared` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Déchargement des données de la table `orderdetail`
--

INSERT INTO `orderdetail` (`idOrder`, `idProduct`, `quantity`, `prepared`) VALUES
(1, 1, '1.00', 0),
(3, 6, '1.00', 0),
(4, 44, '1.00', 0),
(8, 27, '1.00', 0),
(8, 76, '2.00', 0),
(9, 3, '1.00', 0),
(13, 7, '5.00', 0),
(15, 13, '10.00', 0);

--
-- Déclencheurs `orderdetail`
--
DROP TRIGGER IF EXISTS `delete_order_detail`;
DELIMITER $$
CREATE TRIGGER `delete_order_detail` AFTER DELETE ON `orderdetail` FOR EACH ROW CALL updateOrderAmount (
        OLD.idOrder
    )
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `insert_order_detail`;
DELIMITER $$
CREATE TRIGGER `insert_order_detail` AFTER INSERT ON `orderdetail` FOR EACH ROW CALL updateOrderAmount (
        NEW.idOrder
    )
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `update_order_detail`;
DELIMITER $$
CREATE TRIGGER `update_order_detail` AFTER UPDATE ON `orderdetail` FOR EACH ROW CALL updateOrderAmount (
        NEW.idOrder
    )
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `pack`
--

DROP TABLE IF EXISTS `pack`;
CREATE TABLE `pack` (
  `idProduct` int(11) NOT NULL,
  `idPack` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Déchargement des données de la table `pack`
--

INSERT INTO `pack` (`idProduct`, `idPack`) VALUES
(1, 128),
(1, 130),
(4, 128),
(7, 129),
(11, 130),
(13, 130),
(16, 130),
(31, 129),
(32, 128),
(43, 130),
(73, 130);

--
-- Déclencheurs `pack`
--
DROP TRIGGER IF EXISTS `delete_associated`;
DELIMITER $$
CREATE TRIGGER `delete_associated` AFTER DELETE ON `pack` FOR EACH ROW BEGIN
DELETE FROM `associatedproduct` WHERE idProduct=OLD.idProduct AND idAssoproduct=OLD.idPack;
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `insert_associated`;
DELIMITER $$
CREATE TRIGGER `insert_associated` AFTER INSERT ON `pack` FOR EACH ROW BEGIN
DECLARE promo float;
INSERT INTO `associatedproduct`(idProduct,idAssoproduct) VALUES(NEW.idProduct,NEW.idPack);
SET promo = getPackPromo(NEW.idPack);
UPDATE product SET promotion= promo where id=NEW.idPack;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `product`
--

DROP TABLE IF EXISTS `product`;
CREATE TABLE `product` (
  `id` int(11) NOT NULL,
  `name` varchar(60) NOT NULL,
  `comments` text DEFAULT NULL,
  `stock` int(11) NOT NULL,
  `image` text DEFAULT NULL,
  `price` decimal(6,2) NOT NULL,
  `promotion` decimal(6,2) NOT NULL,
  `idSection` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Déchargement des données de la table `product`
--

INSERT INTO `product` (`id`, `name`, `comments`, `stock`, `image`, `price`, `promotion`, `idSection`) VALUES
(1, '1969 Harley Davidson Ultimate Chopper', 'This replica features working kickstand, front suspension, gear-shift lever, footbrake lever, drive chain, wheels and steering. All parts are particularly delicate due to their precise scale and require special care and attention.', 7933, 'S10_1678', '95.70', '0.00', 2),
(2, '1952 Alpine Renault 1300', 'Turnable front wheels; steering function; detailed interior; detailed engine; opening hood; opening trunk; opening doors; and detailed chassis.', 7305, 'S10_1949', '214.30', '0.00', 1),
(3, '1996 Moto Guzzi 1100i', 'Official Moto Guzzi logos and insignias, saddle bags located on side of motorcycle, detailed engine, working steering, working suspension, two leather seats, luggage rack, dual exhaust pipes, small saddle bag located on handle bars, two-tone paint with chrome accents, superior die-cast detail , rotating wheels , working kick stand, diecast metal with plastic parts and baked enamel finish.', 6625, 'S10_2016', '118.94', '0.00', 2),
(4, '2003 Harley-Davidson Eagle Drag Bike', 'Model features, official Harley Davidson logos and insignias, detachable rear wheelie bar, heavy diecast metal with resin parts, authentic multi-color tampo-printed graphics, separate engine drive belts, free-turning front fork, rotating tires and rear racing slick, certificate of authenticity, detailed engine, display stand\r\n, precision diecast replica, baked enamel finish, 1:10 scale model, removable fender, seat and tank cover piece for displaying the superior detail of the v-twin engine', 5582, 'S10_4698', '193.66', '0.00', 2),
(5, '1972 Alfa Romeo GTA', 'Features include: Turnable front wheels; steering function; detailed interior; detailed engine; opening hood; opening trunk; opening doors; and detailed chassis.', 3252, 'S10_4757', '136.00', '0.00', 1),
(6, '1962 LanciaA Delta 16V', 'Features include: Turnable front wheels; steering function; detailed interior; detailed engine; opening hood; opening trunk; opening doors; and detailed chassis.', 6791, 'S10_4962', '147.74', '0.00', 1),
(7, '1968 Ford Mustang', 'Hood, doors and trunk all open to reveal highly detailed interior features. Steering wheel actually turns the front wheels. Color dark green.', 68, 'S12_1099', '194.57', '0.00', 1),
(8, '2001 Ferrari Enzo', 'Turnable front wheels; steering function; detailed interior; detailed engine; opening hood; opening trunk; opening doors; and detailed chassis.', 3619, 'S12_1108', '207.80', '0.00', 1),
(9, '1958 Setra Bus', 'Model features 30 windows, skylights & glare resistant glass, working steering system, original logos', 1579, 'S12_1666', '136.67', '0.00', 6),
(10, '2002 Suzuki XREO', 'Official logos and insignias, saddle bags located on side of motorcycle, detailed engine, working steering, working suspension, two leather seats, luggage rack, dual exhaust pipes, small saddle bag located on handle bars, two-tone paint with chrome accents, superior die-cast detail , rotating wheels , working kick stand, diecast metal with plastic parts and baked enamel finish.', 9997, 'S12_2823', '150.62', '0.00', 2),
(11, '1969 Corvair Monza', '1:18 scale die-cast about 10\" long doors open, hood opens, trunk opens and wheels roll', 6906, 'S12_3148', '151.08', '0.00', 1),
(12, '1968 Dodge Charger', '1:12 scale model of a 1968 Dodge Charger. Hood, doors and trunk all open to reveal highly detailed interior features. Steering wheel actually turns the front wheels. Color black', 9123, 'S12_3380', '117.44', '0.00', 1),
(13, '1969 Ford Falcon', 'Turnable front wheels; steering function; detailed interior; detailed engine; opening hood; opening trunk; opening doors; and detailed chassis.', 1049, 'S12_3891', '173.02', '0.00', 1),
(14, '1970 Plymouth Hemi Cuda', 'Very detailed 1970 Plymouth Cuda model in 1:12 scale. The Cuda is generally accepted as one of the fastest original muscle cars from the 1970s. This model is a reproduction of one of the orginal 652 cars built in 1970. Red color.', 5663, 'S12_3990', '79.80', '0.00', 1),
(15, '1957 Chevy Pickup', '1:12 scale die-cast about 20\" long Hood opens, Rubber wheels', 6125, 'S12_4473', '118.50', '0.00', 6),
(16, '1969 Dodge Charger', 'Detailed model of the 1969 Dodge Charger. This model includes finely detailed interior and exterior features. Painted in red and white.', 7323, 'S12_4675', '115.16', '0.00', 1),
(17, '1940 Ford Pickup Truck', 'This model features soft rubber tires, working steering, rubber mud guards, authentic Ford logos, detailed undercarriage, opening doors and hood,  removable split rear gate, full size spare mounted in bed, detailed interior with opening glove box', 2613, 'S18_1097', '116.67', '0.00', 6),
(18, '1993 Mazda RX-7', 'This model features, opening hood, opening doors, detailed engine, rear spoiler, opening trunk, working steering, tinted windows, baked enamel finish. Color red.', 3975, 'S18_1129', '141.54', '0.00', 1),
(19, '1937 Lincoln Berline', 'Features opening engine cover, doors, trunk, and fuel filler cap. Color black', 8693, 'S18_1342', '102.74', '0.00', 7),
(20, '1936 Mercedes-Benz 500K Special Roadster', 'This 1:18 scale replica is constructed of heavy die-cast metal and has all the features of the original: working doors and rumble seat, independent spring suspension, detailed interior, working steering system, and a bifold hood that reveals an engine so accurate that it even includes the wiring. All this is topped off with a baked enamel finish. Color white.', 8635, 'S18_1367', '53.91', '0.00', 7),
(21, '1965 Aston Martin DB5', 'Die-cast model of the silver 1965 Aston Martin DB5 in silver. This model includes full wire wheels and doors that open with fully detailed passenger compartment. In 1:18 scale, this model measures approximately 10 inches/20 cm long.', 9042, 'S18_1589', '124.44', '0.00', 1),
(22, '1980s Black Hawk Helicopter', '1:18 scale replica of actual Army\'s UH-60L BLACK HAWK Helicopter. 100% hand-assembled. Features rotating rotor blades, propeller blades and rubber wheels.', 5330, 'S18_1662', '157.69', '0.00', 3),
(23, '1917 Grand Touring Sedan', 'This 1:18 scale replica of the 1917 Grand Touring car has all the features you would expect from museum quality reproductions: all four doors and bi-fold hood opening, detailed engine and instrument panel, chrome-look trim, and tufted upholstery, all topped off with a factory baked-enamel finish.', 2724, 'S18_1749', '170.00', '0.00', 7),
(24, '1948 Porsche 356-A Roadster', 'This precision die-cast replica features opening doors, superb detail and craftsmanship, working steering system, opening forward compartment, opening rear trunk with removable spare, 4 wheel independent spring suspension as well as factory baked enamel finish.', 8826, 'S18_1889', '77.00', '0.00', 1),
(25, '1995 Honda Civic', 'This model features, opening hood, opening doors, detailed engine, rear spoiler, opening trunk, working steering, tinted windows, baked enamel finish. Color yellow.', 9772, 'S18_1984', '142.25', '0.00', 1),
(26, '1998 Chrysler Plymouth Prowler', 'Turnable front wheels; steering function; detailed interior; detailed engine; opening hood; opening trunk; opening doors; and detailed chassis.', 4724, 'S18_2238', '163.73', '0.00', 1),
(27, '1911 Ford Town Car', 'Features opening hood, opening doors, opening trunk, wide white wall tires, front door arm rests, working steering system.', 540, 'S18_2248', '60.54', '0.00', 7),
(28, '1964 Mercedes Tour Bus', 'Exact replica. 100+ parts. working steering system, original logos', 8258, 'S18_2319', '122.73', '0.00', 6),
(29, '1932 Model A Ford J-Coupe', 'This model features grille-mounted chrome horn, lift-up louvered hood, fold-down rumble seat, working steering system, chrome-covered spare, opening doors, detailed and wired engine', 9354, 'S18_2325', '127.13', '0.00', 7),
(30, '1926 Ford Fire Engine', 'Gleaming red handsome appearance. Everything is here the fire hoses, ladder, axes, bells, lanterns, ready to fight any inferno.', 2018, 'S18_2432', '60.77', '0.00', 6),
(31, 'P-51-D Mustang', 'Has retractable wheels and comes with a stand', 992, 'S18_2581', '84.48', '0.00', 3),
(32, '1936 Harley Davidson El Knucklehead', 'Intricately detailed with chrome accents and trim, official die-struck logos and baked enamel finish.', 4357, 'S18_2625', '60.57', '0.00', 2),
(33, '1928 Mercedes-Benz SSK', 'This 1:18 replica features grille-mounted chrome horn, lift-up louvered hood, fold-down rumble seat, working steering system, chrome-covered spare, opening doors, detailed and wired engine. Color black.', 548, 'S18_2795', '168.75', '0.00', 7),
(34, '1999 Indy 500 Monte Carlo SS', 'Features include opening and closing doors. Color: Red', 8164, 'S18_2870', '132.00', '0.00', 1),
(35, '1913 Ford Model T Speedster', 'This 250 part reproduction includes moving handbrakes, clutch, throttle and foot pedals, squeezable horn, detailed wired engine, removable water, gas, and oil cans, pivoting monocle windshield, all topped with a baked enamel red finish. Each replica comes with an Owners Title and Certificate of Authenticity. Color red.', 4189, 'S18_2949', '101.31', '0.00', 7),
(36, '1934 Ford V8 Coupe', 'Chrome Trim, Chrome Grille, Opening Hood, Opening Doors, Opening Trunk, Detailed Engine, Working Steering System', 5649, 'S18_2957', '62.46', '0.00', 7),
(37, '1999 Yamaha Speed Boat', 'Exact replica. Wood and Metal. Many extras including rigging, long boats, pilot house, anchors, etc. Comes with three masts, all square-rigged.', 4259, 'S18_3029', '86.02', '0.00', 4),
(38, '18th Century Vintage Horse Carriage', 'Hand crafted diecast-like metal horse carriage is re-created in about 1:18 scale of antique horse carriage. This antique style metal Stagecoach is all hand-assembled with many different parts.\r\n\r\nThis collectible metal horse carriage is painted in classic Red, and features turning steering wheel and is entirely hand-finished.', 5992, 'S18_3136', '104.72', '0.00', 7),
(39, '1903 Ford Model A', 'Features opening trunk,  working steering system', 3913, 'S18_3140', '136.59', '0.00', 7),
(40, '1992 Ferrari 360 Spider red', 'his replica features opening doors, superb detail and craftsmanship, working steering system, opening forward compartment, opening rear trunk with removable spare, 4 wheel independent spring suspension as well as factory baked enamel finish.', 8347, 'S18_3232', '169.34', '0.00', 1),
(41, '1985 Toyota Supra', 'This model features soft rubber tires, working steering, rubber mud guards, authentic Ford logos, detailed undercarriage, opening doors and hood, removable split rear gate, full size spare mounted in bed, detailed interior with opening glove box', 7733, 'S18_3233', '107.57', '0.00', 1),
(42, 'Collectable Wooden Train', 'Hand crafted wooden toy train set is in about 1:18 scale, 25 inches in total length including 2 additional carts, of actual vintage train. This antique style wooden toy train model set is all hand-assembled with 100% wood.', 6450, 'S18_3259', '100.84', '0.00', 5),
(43, '1969 Dodge Super Bee', 'This replica features opening doors, superb detail and craftsmanship, working steering system, opening forward compartment, opening rear trunk with removable spare, 4 wheel independent spring suspension as well as factory baked enamel finish.', 1917, 'S18_3278', '80.41', '0.00', 1),
(44, '1917 Maxwell Touring Car', 'Features Gold Trim, Full Size Spare Tire, Chrome Trim, Chrome Grille, Opening Hood, Opening Doors, Opening Trunk, Detailed Engine, Working Steering System', 7913, 'S18_3320', '99.21', '0.00', 7),
(45, '1976 Ford Gran Torino', 'Highly detailed 1976 Ford Gran Torino \"Starsky and Hutch\" diecast model. Very well constructed and painted in red and white patterns.', 9127, 'S18_3482', '146.99', '0.00', 1),
(46, '1948 Porsche Type 356 Roadster', 'This model features working front and rear suspension on accurately replicated and actuating shock absorbers as well as opening engine cover, rear stabilizer flap,  and 4 opening doors.', 8990, 'S18_3685', '141.28', '0.00', 1),
(47, '1957 Vespa GS150', 'Features rotating wheels , working kick stand. Comes with stand.', 7689, 'S18_3782', '62.17', '0.00', 2),
(48, '1941 Chevrolet Special Deluxe Cabriolet', 'Features opening hood, opening doors, opening trunk, wide white wall tires, front door arm rests, working steering system, leather upholstery. Color black.', 2378, 'S18_3856', '105.87', '0.00', 7),
(49, '1970 Triumph Spitfire', 'Features include opening and closing doors. Color: White.', 5545, 'S18_4027', '143.62', '0.00', 1),
(50, '1932 Alfa Romeo 8C2300 Spider Sport', 'This 1:18 scale precision die cast replica features the 6 front headlights of the original, plus a detailed version of the 142 horsepower straight 8 engine, dual spares and their famous comprehensive dashboard. Color black.', 6553, 'S18_4409', '92.03', '0.00', 7),
(51, '1904 Buick Runabout', 'Features opening trunk,  working steering system', 8290, 'S18_4522', '87.77', '0.00', 7),
(52, '1940s Ford truck', 'This 1940s Ford Pick-Up truck is re-created in 1:18 scale of original 1940s Ford truck. This antique style metal 1940s Ford Flatbed truck is all hand-assembled. This collectible 1940\'s Pick-Up truck is painted in classic dark green color, and features rotating wheels.', 3128, 'S18_4600', '121.08', '0.00', 6),
(53, '1939 Cadillac Limousine', 'Features completely detailed interior including Velvet flocked drapes,deluxe wood grain floor, and a wood grain casket with seperate chrome handles', 6645, 'S18_4668', '50.31', '0.00', 7),
(54, '1957 Corvette Convertible', '1957 die cast Corvette Convertible in Roman Red with white sides and whitewall tires. 1:18 scale quality die-cast with detailed engine and underbvody. Now you can own The Classic Corvette.', 1249, 'S18_4721', '148.80', '0.00', 1),
(55, '1957 Ford Thunderbird', 'This 1:18 scale precision die-cast replica, with its optional porthole hardtop and factory baked-enamel Thunderbird Bronze finish, is a 100% accurate rendition of this American classic.', 3209, 'S18_4933', '71.27', '0.00', 1),
(56, '1970 Chevy Chevelle SS 454', 'This model features rotating wheels, working streering system and opening doors. All parts are particularly delicate due to their precise scale and require special care and attention. It should not be picked up by the doors, roof, hood or trunk.', 1005, 'S24_1046', '73.49', '0.00', 1),
(57, '1970 Dodge Coronet', '1:24 scale die-cast about 18\" long doors open, hood opens and rubber wheels', 4074, 'S24_1444', '57.80', '0.00', 1),
(58, '1997 BMW R 1100 S', 'Detailed scale replica with working suspension and constructed from over 70 parts', 7003, 'S24_1578', '112.70', '0.00', 2),
(59, '1966 Shelby Cobra 427 S/C', 'This diecast model of the 1966 Shelby Cobra 427 S/C includes many authentic details and operating parts. The 1:24 scale model of this iconic lighweight sports car from the 1960s comes in silver and it\'s own display case.', 8197, 'S24_1628', '50.31', '0.00', 1),
(60, '1928 British Royal Navy Airplane', 'Official logos and insignias', 3627, 'S24_1785', '109.42', '0.00', 3),
(61, '1939 Chevrolet Deluxe Coupe', 'This 1:24 scale die-cast replica of the 1939 Chevrolet Deluxe Coupe has the same classy look as the original. Features opening trunk, hood and doors and a showroom quality baked enamel finish.', 7332, 'S24_1937', '33.19', '0.00', 7),
(62, '1960 BSA Gold Star DBD34', 'Detailed scale replica with working suspension and constructed from over 70 parts', 15, 'S24_2000', '76.17', '0.00', 2),
(63, '18th century schooner', 'All wood with canvas sails. Many extras including rigging, long boats, pilot house, anchors, etc. Comes with 4 masts, all square-rigged.', 1898, 'S24_2011', '122.89', '0.00', 4),
(64, '1938 Cadillac V-16 Presidential Limousine', 'This 1:24 scale precision die cast replica of the 1938 Cadillac V-16 Presidential Limousine has all the details of the original, from the flags on the front to an opening back seat compartment complete with telephone and rifle. Features factory baked-enamel black finish, hood goddess ornament, working jump seats.', 2847, 'S24_2022', '44.80', '0.00', 7),
(65, '1962 Volkswagen Microbus', 'This 1:18 scale die cast replica of the 1962 Microbus is loaded with features: A working steering system, opening front doors and tailgate, and famous two-tone factory baked enamel finish, are all topped of by the sliding, real fabric, sunroof.', 2327, 'S24_2300', '127.79', '0.00', 6),
(66, '1982 Ducati 900 Monster', 'Features two-tone paint with chrome accents, superior die-cast detail , rotating wheels , working kick stand', 6840, 'S24_2360', '69.26', '0.00', 2),
(67, '1949 Jaguar XK 120', 'Precision-engineered from original Jaguar specification in perfect scale ratio. Features opening doors, superb detail and craftsmanship, working steering system, opening forward compartment, opening rear trunk with removable spare, 4 wheel independent spring suspension as well as factory baked enamel finish.', 2350, 'S24_2766', '90.87', '0.00', 1),
(68, '1958 Chevy Corvette Limited Edition', 'The operating parts of this 1958 Chevy Corvette Limited Edition are particularly delicate due to their precise scale and require special care and attention. Features rotating wheels, working streering, opening doors and trunk. Color dark green.', 2542, 'S24_2840', '35.36', '0.00', 1),
(69, '1900s Vintage Bi-Plane', 'Hand crafted diecast-like metal bi-plane is re-created in about 1:24 scale of antique pioneer airplane. All hand-assembled with many different parts. Hand-painted in classic yellow and features correct markings of original airplane.', 5942, 'S24_2841', '68.51', '0.00', 3),
(70, '1952 Citroen-15CV', 'Precision crafted hand-assembled 1:18 scale reproduction of the 1952 15CV, with its independent spring suspension, working steering system, opening doors and hood, detailed engine and instrument panel, all topped of with a factory fresh baked enamel finish.', 1452, 'S24_2887', '117.44', '0.00', 1),
(71, '1982 Lamborghini Diablo', 'This replica features opening doors, superb detail and craftsmanship, working steering system, opening forward compartment, opening rear trunk with removable spare, 4 wheel independent spring suspension as well as factory baked enamel finish.', 7723, 'S24_2972', '37.76', '0.00', 1),
(72, '1912 Ford Model T Delivery Wagon', 'This model features chrome trim and grille, opening hood, opening doors, opening trunk, detailed engine, working steering system. Color white.', 9173, 'S24_3151', '88.51', '0.00', 7),
(73, '1969 Chevrolet Camaro Z28', '1969 Z/28 Chevy Camaro 1:24 scale replica. The operating parts of this limited edition 1:24 scale diecast model car 1969 Chevy Camaro Z28- hood, trunk, wheels, streering, suspension and doors- are particularly delicate due to their precise scale and require special care and attention.', 4695, 'S24_3191', '85.61', '0.00', 1),
(74, '1971 Alpine Renault 1600s', 'This 1971 Alpine Renault 1600s replica Features opening doors, superb detail and craftsmanship, working steering system, opening forward compartment, opening rear trunk with removable spare, 4 wheel independent spring suspension as well as factory baked enamel finish.', 7995, 'S24_3371', '61.23', '0.00', 1),
(75, '1937 Horch 930V Limousine', 'Features opening hood, opening doors, opening trunk, wide white wall tires, front door arm rests, working steering system', 2902, 'S24_3420', '65.75', '0.00', 7),
(76, '2002 Chevy Corvette', 'The operating parts of this limited edition Diecast 2002 Chevy Corvette 50th Anniversary Pace car Limited Edition are particularly delicate due to their precise scale and require special care and attention. Features rotating wheels, poseable streering, opening doors and trunk.', 9446, 'S24_3432', '107.08', '0.00', 1),
(77, '1940 Ford Delivery Sedan', 'Chrome Trim, Chrome Grille, Opening Hood, Opening Doors, Opening Trunk, Detailed Engine, Working Steering System. Color black.', 6621, 'S24_3816', '83.86', '0.00', 7),
(78, '1956 Porsche 356A Coupe', 'Features include: Turnable front wheels; steering function; detailed interior; detailed engine; opening hood; opening trunk; opening doors; and detailed chassis.', 6600, 'S24_3856', '140.43', '0.00', 1),
(79, 'Corsair F4U ( Bird Cage)', 'Has retractable wheels and comes with a stand. Official logos and insignias.', 6812, 'S24_3949', '68.24', '0.00', 3),
(80, '1936 Mercedes Benz 500k Roadster', 'This model features grille-mounted chrome horn, lift-up louvered hood, fold-down rumble seat, working steering system and rubber wheels. Color black.', 2081, 'S24_3969', '41.03', '0.00', 7),
(81, '1992 Porsche Cayenne Turbo Silver', 'This replica features opening doors, superb detail and craftsmanship, working steering system, opening forward compartment, opening rear trunk with removable spare, 4 wheel independent spring suspension as well as factory baked enamel finish.', 6582, 'S24_4048', '118.28', '0.00', 1),
(82, '1936 Chrysler Airflow', 'Features opening trunk,  working steering system. Color dark green.', 4710, 'S24_4258', '97.39', '0.00', 7),
(83, '1900s Vintage Tri-Plane', 'Hand crafted diecast-like metal Triplane is Re-created in about 1:24 scale of antique pioneer airplane. This antique style metal triplane is all hand-assembled with many different parts.', 2756, 'S24_4278', '72.45', '0.00', 3),
(84, '1961 Chevrolet Impala', 'This 1:18 scale precision die-cast reproduction of the 1961 Chevrolet Impala has all the features-doors, hood and trunk that open; detailed 409 cubic-inch engine; chrome dashboard and stick shift, two-tone interior; working steering system; all topped of with a factory baked-enamel finish.', 7869, 'S24_4620', '80.84', '0.00', 1),
(85, '1980’s GM Manhattan Express', 'This 1980’s era new look Manhattan express is still active, running from the Bronx to mid-town Manhattan. Has 35 opeining windows and working lights. Needs a battery.', 5099, 'S32_1268', '96.31', '0.00', 6),
(86, '1997 BMW F650 ST', 'Features official die-struck logos and baked enamel finish. Comes with stand.', 178, 'S32_1374', '99.89', '0.00', 2),
(87, '1982 Ducati 996 R', 'Features rotating wheels , working kick stand. Comes with stand.', 9241, 'S32_2206', '40.23', '0.00', 2),
(88, '1954 Greyhound Scenicruiser', 'Model features bi-level seating, 50 windows, skylights & glare resistant glass, working steering system, original logos', 2874, 'S32_2509', '54.11', '0.00', 6),
(89, '1950\'s Chicago Surface Lines Streetcar', 'This streetcar is a joy to see. It has 80 separate windows, electric wire guides, detailed interiors with seats, poles and drivers controls, rolling and turning wheel assemblies, plus authentic factory baked-enamel finishes (Green Hornet for Chicago and Cream and Crimson for Boston).', 8601, 'S32_3207', '62.14', '0.00', 5),
(90, '1996 Peterbilt 379 Stake Bed with Outrigger', 'This model features, opening doors, detailed engine, working steering, tinted windows, detailed interior, die-struck logos, removable stakes operating outriggers, detachable second trailer, functioning 360-degree self loader, precision molded resin trailer and trim, baked enamel finish on cab', 814, 'S32_3522', '64.64', '0.00', 6),
(91, '1928 Ford Phaeton Deluxe', 'This model features grille-mounted chrome horn, lift-up louvered hood, fold-down rumble seat, working steering system', 136, 'S32_4289', '68.79', '0.00', 7),
(92, '1974 Ducati 350 Mk3 Desmo', 'This model features two-tone paint with chrome accents, superior die-cast detail , rotating wheels , working kick stand', 3341, 'S32_4485', '102.05', '0.00', 2),
(93, '1930 Buick Marquette Phaeton', 'Features opening trunk,  working steering system', 7062, 'S50_1341', '43.64', '0.00', 7),
(94, 'Diamond T620 Semi-Skirted Tanker', 'This limited edition model is licensed and perfectly scaled for Lionel Trains. The Diamond T620 has been produced in solid precision diecast and painted with a fire baked enamel finish. It comes with a removable tanker and is a perfect model to add authenticity to your static train or car layout or to just have on display.', 1016, 'S50_1392', '115.75', '0.00', 6),
(95, '1962 City of Detroit Streetcar', 'This streetcar is a joy to see. It has 99 separate windows, electric wire guides, detailed interiors with seats, poles and drivers controls, rolling and turning wheel assemblies, plus authentic factory baked-enamel finishes (Green Hornet for Chicago and Cream and Crimson for Boston).', 1645, 'S50_1514', '58.58', '0.00', 5),
(96, '2002 Yamaha YZR M1', 'Features rotating wheels , working kick stand. Comes with stand.', 600, 'S50_4713', '81.36', '0.00', 2),
(97, 'The Schooner Bluenose', 'All wood with canvas sails. Measures 31 1/2 inches in Length, 22 inches High and 4 3/4 inches Wide. Many extras.\r\nThe schooner Bluenose was built in Nova Scotia in 1921 to fish the rough waters off the coast of Newfoundland. Because of the Bluenose racing prowess she became the pride of all Canadians. Still featured on stamps and the Canadian dime, the Bluenose was lost off Haiti in 1946.', 1897, 'S700_1138', '66.67', '0.00', 4),
(98, 'American Airlines: B767-300', 'Exact replia with official logos and insignias and retractable wheels', 5841, 'S700_1691', '91.34', '0.00', 3),
(99, 'The Mayflower', 'Measures 31 1/2 inches Long x 25 1/2 inches High x 10 5/8 inches Wide\r\nAll wood with canvas sail. Extras include long boats, rigging, ladders, railing, anchors, side cannons, hand painted, etc.', 737, 'S700_1938', '86.61', '0.00', 4),
(100, 'HMS Bounty', 'Measures 30 inches Long x 27 1/2 inches High x 4 3/4 inches Wide. \r\nMany extras including rigging, long boats, pilot house, anchors, etc. Comes with three masts, all square-rigged.', 3501, 'S700_2047', '90.52', '0.00', 4),
(101, 'America West Airlines B757-200', 'Official logos and insignias. Working steering system. Rotating jet engines', 9653, 'S700_2466', '99.72', '0.00', 3),
(102, 'The USS Constitution Ship', 'All wood with canvas sails. Measures 31 1/2\" Length x 22 3/8\" High x 8 1/4\" Width. Extras include 4 boats on deck, sea sprite on bow, anchors, copper railing, pilot houses, etc.', 7083, 'S700_2610', '72.28', '0.00', 4),
(103, '1982 Camaro Z28', 'Features include opening and closing doors. Color: White. \r\nMeasures approximately 9 1/2\" Long.', 6934, 'S700_2824', '101.15', '0.00', 1),
(104, 'ATA: B757-300', 'Exact replia with official logos and insignias and retractable wheels', 7106, 'S700_2834', '118.65', '0.00', 3),
(105, 'F/A 18 Hornet 1/72', '10\" Wingspan with retractable landing gears.Comes with pilot', 551, 'S700_3167', '80.00', '0.00', 3),
(106, 'The Titanic', 'Completed model measures 19 1/2 inches long, 9 inches high, 3inches wide and is in barn red/black. All wood and metal.', 1956, 'S700_3505', '100.17', '0.00', 4),
(107, 'The Queen Mary', 'Exact replica. Wood and Metal. Many extras including rigging, long boats, pilot house, anchors, etc. Comes with three masts, all square-rigged.', 5088, 'S700_3962', '99.31', '0.00', 4),
(108, 'American Airlines: MD-11S', 'Polished finish. Exact replia with official logos and insignias and retractable wheels', 8820, 'S700_4002', '74.03', '0.00', 3),
(109, 'Boeing X-32A JSF', '10\" Wingspan with retractable landing gears.Comes with pilot', 4857, 'S72_1253', '49.66', '0.00', 3),
(110, 'Pont Yacht', 'Measures 38 inches Long x 33 3/4 inches High. Includes a stand.\r\nMany extras including rigging, long boats, pilot house, anchors, etc. Comes with 2 masts, all square-rigged', 414, 'S72_3212', '54.60', '0.00', 4),
(128, 'Harley pack', '', 0, '', '340.00', '-9.93', 2),
(129, 'Mustangs', '', 0, '', '270.00', '-9.05', 7),
(130, '1969', '', 0, '', '660.00', '-40.98', 7);

--
-- Déclencheurs `product`
--
DROP TRIGGER IF EXISTS `update_product_price`;
DELIMITER $$
CREATE TRIGGER `update_product_price` BEFORE UPDATE ON `product` FOR EACH ROW BEGIN
if (OLD.price<>NEW.price) THEN
    SET NEW.promotion = getPackPromo(NEW.id);
END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `section`
--

DROP TABLE IF EXISTS `section`;
CREATE TABLE `section` (
  `id` int(11) NOT NULL,
  `name` varchar(60) NOT NULL,
  `description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Déchargement des données de la table `section`
--

INSERT INTO `section` (`id`, `name`, `description`) VALUES
(1, 'Classic Cars', 'Attention car enthusiasts: Make your wildest car ownership dreams come true. Whether you are looking for classic muscle cars, dream sports cars or movie-inspired miniatures, you will find great choices in this category. These replicas feature superb attention to detail and craftsmanship and offer features such as working steering system, opening forward compartment, opening rear trunk with removable spare wheel, 4-wheel independent spring suspension, and so on. The models range in size from 1:10 to 1:24 scale and include numerous limited edition and several out-of-production vehicles. All models include a certificate of authenticity from their manufacturers and come fully assembled and ready for display in the home or office.'),
(2, 'Motorcycles', 'Our motorcycles are state of the art replicas of classic as well as contemporary motorcycle legends such as Harley Davidson, Ducati and Vespa. Models contain stunning details such as official logos, rotating wheels, working kickstand, front suspension, gear-shift lever, footbrake lever, and drive chain. Materials used include diecast and plastic. The models range in size from 1:10 to 1:50 scale and include numerous limited edition and several out-of-production vehicles. All models come fully assembled and ready for display in the home or office. Most include a certificate of authenticity.'),
(3, 'Planes', 'Unique, diecast airplane and helicopter replicas suitable for collections, as well as home, office or classroom decorations. Models contain stunning details such as official logos and insignias, rotating jet engines and propellers, retractable wheels, and so on. Most come fully assembled and with a certificate of authenticity from their manufacturers.'),
(4, 'Ships', 'The perfect holiday or anniversary gift for executives, clients, friends, and family. These handcrafted model ships are unique, stunning works of art that will be treasured for generations! They come fully assembled and ready for display in the home or office. We guarantee the highest quality, and best value.'),
(5, 'Trains', 'Model trains are a rewarding hobby for enthusiasts of all ages. Whether you\'re looking for collectible wooden trains, electric streetcars or locomotives, you\'ll find a number of great choices for any budget within this category. The interactive aspect of trains makes toy trains perfect for young children. The wooden train sets are ideal for children under the age of 5.'),
(6, 'Trucks and Buses', 'The Truck and Bus models are realistic replicas of buses and specialized trucks produced from the early 1920s to present. The models range in size from 1:12 to 1:50 scale and include numerous limited edition and several out-of-production vehicles. Materials used include tin, diecast and plastic. All models include a certificate of authenticity from their manufacturers and are a perfect ornament for the home and office.'),
(7, 'Vintage Cars', 'Our Vintage Car models realistically portray automobiles produced from the early 1900s through the 1940s. Materials used include Bakelite, diecast, plastic and wood. Most of the replicas are in the 1:18 and 1:24 scale sizes, which provide the optimum in detail and accuracy. Prices range from $30.00 up to $180.00 for some special limited edition replicas. All models include a certificate of authenticity from their manufacturers and come fully assembled and ready for display in the home or office.');

-- --------------------------------------------------------

--
-- Structure de la table `slot`
--

DROP TABLE IF EXISTS `slot`;
CREATE TABLE `slot` (
  `id` int(11) NOT NULL,
  `name` time NOT NULL,
  `days` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Déchargement des données de la table `slot`
--

INSERT INTO `slot` (`id`, `name`, `days`) VALUES
(1, '09:00:00', '1,2,3,4,5'),
(2, '09:15:00', '1,2,3,4,5'),
(3, '09:30:00', '1,2,3,4,5'),
(4, '09:45:00', '1,2,3,4,5'),
(5, '10:00:00', '1,2,3,4,5'),
(6, '10:15:00', '1,2,3,4,5'),
(7, '10:30:00', '1,2,3,4,5'),
(8, '10:45:00', '1,2,3,4,5'),
(9, '11:00:00', '1,2,3,4,5'),
(10, '11:15:00', '1,2,3,4,5'),
(11, '11:30:00', '1,2,3,4,5'),
(12, '11:45:00', '1,2,3,4,5'),
(13, '12:00:00', '1,2,3,4,5'),
(14, '14:00:00', '1,2,3,4,5'),
(15, '14:15:00', '1,2,3,4,5'),
(16, '14:30:00', '1,2,3,4,5'),
(17, '14:45:00', '1,2,3,4,5'),
(18, '15:00:00', '1,2,3,4,5'),
(19, '15:15:00', '1,2,3,4,5'),
(20, '15:30:00', '1,2,3,4,5'),
(21, '15:45:00', '1,2,3,4,5'),
(22, '16:00:00', '1,2,3,4,5'),
(23, '16:15:00', '1,2,3,4,5'),
(24, '16:30:00', '1,2,3,4,5'),
(25, '16:45:00', '1,2,3,4,5'),
(26, '17:00:00', '1,2,3,4,5'),
(27, '17:15:00', '1,2,3,4,5'),
(28, '17:30:00', '1,2,3,4,5'),
(29, '17:45:00', '1,2,3,4,5');

-- --------------------------------------------------------

--
-- Structure de la table `timeslot`
--

DROP TABLE IF EXISTS `timeslot`;
CREATE TABLE `timeslot` (
  `id` int(11) NOT NULL,
  `slotDate` datetime NOT NULL,
  `full` tinyint(1) NOT NULL DEFAULT 0,
  `expired` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Déchargement des données de la table `timeslot`
--

INSERT INTO `timeslot` (`id`, `slotDate`, `full`, `expired`) VALUES
(1, '2021-03-03 12:00:00', 0, 0),
(2, '2021-03-04 12:00:00', 1, 0),
(3, '2021-03-06 16:00:00', 0, 0);

-- --------------------------------------------------------

--
-- Structure de la table `user`
--

DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
  `id` int(11) NOT NULL,
  `name` varchar(60) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Déchargement des données de la table `user`
--

INSERT INTO `user` (`id`, `name`, `email`, `password`) VALUES
(1, 'SMITH Abraham', 'a.smith@email.net', '0000'),
(2, 'DOE John', 'j.doe@email.net', '0000'),
(3, 'STAN Johan', 'j.stan@email.net', '1234');

--
-- Déclencheurs `user`
--
DROP TRIGGER IF EXISTS `insert_user_basket`;
DELIMITER $$
CREATE TRIGGER `insert_user_basket` AFTER INSERT ON `user` FOR EACH ROW BEGIN
INSERT INTO basket(name,idUser) VALUES('Mis de côté',NEW.id);
END
$$
DELIMITER ;

--
-- Index pour les tables déchargées
--

--
-- Index pour la table `associatedproduct`
--
ALTER TABLE `associatedproduct`
  ADD PRIMARY KEY (`idProduct`,`idAssoProduct`),
  ADD KEY `productsasso_ibfk_1` (`idAssoProduct`);

--
-- Index pour la table `basket`
--
ALTER TABLE `basket`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idUser` (`idUser`);

--
-- Index pour la table `basketdetail`
--
ALTER TABLE `basketdetail`
  ADD PRIMARY KEY (`idBasket`,`idProduct`),
  ADD KEY `idProduct` (`idProduct`);

--
-- Index pour la table `employee`
--
ALTER TABLE `employee`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `order`
--
ALTER TABLE `order`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idUser` (`idUser`),
  ADD KEY `idEmployee` (`idEmployee`),
  ADD KEY `idTimeslot` (`idTimeslot`);

--
-- Index pour la table `orderdetail`
--
ALTER TABLE `orderdetail`
  ADD PRIMARY KEY (`idOrder`,`idProduct`),
  ADD KEY `idProduct` (`idProduct`);

--
-- Index pour la table `pack`
--
ALTER TABLE `pack`
  ADD PRIMARY KEY (`idProduct`,`idPack`),
  ADD KEY `idProduct` (`idPack`);

--
-- Index pour la table `product`
--
ALTER TABLE `product`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idSection` (`idSection`);
ALTER TABLE `product` ADD FULLTEXT KEY `name` (`name`);

--
-- Index pour la table `section`
--
ALTER TABLE `section`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `slot`
--
ALTER TABLE `slot`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `timeslot`
--
ALTER TABLE `timeslot`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `slotDate` (`slotDate`);

--
-- Index pour la table `user`
--
ALTER TABLE `user`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT pour les tables déchargées
--

--
-- AUTO_INCREMENT pour la table `basket`
--
ALTER TABLE `basket`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT pour la table `employee`
--
ALTER TABLE `employee`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT pour la table `order`
--
ALTER TABLE `order`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT pour la table `product`
--
ALTER TABLE `product`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=131;

--
-- AUTO_INCREMENT pour la table `section`
--
ALTER TABLE `section`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- AUTO_INCREMENT pour la table `slot`
--
ALTER TABLE `slot`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=30;

--
-- AUTO_INCREMENT pour la table `timeslot`
--
ALTER TABLE `timeslot`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT pour la table `user`
--
ALTER TABLE `user`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- Contraintes pour les tables déchargées
--

--
-- Contraintes pour la table `associatedproduct`
--
ALTER TABLE `associatedproduct`
  ADD CONSTRAINT `associatedproduct_ibfk_1` FOREIGN KEY (`idAssoProduct`) REFERENCES `product` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `associatedproduct_ibfk_2` FOREIGN KEY (`idProduct`) REFERENCES `product` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Contraintes pour la table `basket`
--
ALTER TABLE `basket`
  ADD CONSTRAINT `basket_ibfk_1` FOREIGN KEY (`idUser`) REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Contraintes pour la table `basketdetail`
--
ALTER TABLE `basketdetail`
  ADD CONSTRAINT `basketdetail_ibfk_1` FOREIGN KEY (`idBasket`) REFERENCES `basket` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `basketdetail_ibfk_2` FOREIGN KEY (`idProduct`) REFERENCES `product` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Contraintes pour la table `order`
--
ALTER TABLE `order`
  ADD CONSTRAINT `order_ibfk_1` FOREIGN KEY (`idUser`) REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `order_ibfk_2` FOREIGN KEY (`idEmployee`) REFERENCES `employee` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `order_ibfk_3` FOREIGN KEY (`idTimeslot`) REFERENCES `timeslot` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Contraintes pour la table `orderdetail`
--
ALTER TABLE `orderdetail`
  ADD CONSTRAINT `orderdetail_ibfk_1` FOREIGN KEY (`idOrder`) REFERENCES `order` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `orderdetail_ibfk_2` FOREIGN KEY (`idProduct`) REFERENCES `product` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Contraintes pour la table `pack`
--
ALTER TABLE `pack`
  ADD CONSTRAINT `pack_ibfk_1` FOREIGN KEY (`idProduct`) REFERENCES `product` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `pack_ibfk_2` FOREIGN KEY (`idPack`) REFERENCES `product` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Contraintes pour la table `product`
--
ALTER TABLE `product`
  ADD CONSTRAINT `product_ibfk_1` FOREIGN KEY (`idSection`) REFERENCES `section` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
