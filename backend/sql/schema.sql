-- Shipon MySQL schema
--
-- This script provisions the tables expected by backend/server.js.
--
-- Usage:
--   mysql -u <user> -p<password> <database> < backend/sql/schema.sql;

SET NAMES utf8mb4;
SET time_zone = '+00:00';

CREATE TABLE IF NOT EXISTS `users` (
  `Id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `First_Name` VARCHAR(100) NOT NULL,
  `Last_Name` VARCHAR(100) NOT NULL,
  `Company_Name` VARCHAR(150) DEFAULT NULL,
  `Email` VARCHAR(191) NOT NULL,
  `Password` VARCHAR(191) NOT NULL,
  `Phone_Number` VARCHAR(50) DEFAULT NULL,
  `Image` VARCHAR(255) DEFAULT NULL,
  `Role` VARCHAR(20) NOT NULL DEFAULT 'customer',
  `AddressLine1` VARCHAR(255) DEFAULT NULL,
  `AddressLine2` VARCHAR(255) DEFAULT NULL,
  `City` VARCHAR(120) DEFAULT NULL,
  `PostCode` VARCHAR(30) DEFAULT NULL,
  `Country` VARCHAR(120) DEFAULT NULL,
  `State` VARCHAR(120) DEFAULT NULL,
  `Banned_Sites` TEXT,
  `Notes` TEXT,
  `Away_Status` VARCHAR(20) DEFAULT 'Available',
  `Away_Start` DATETIME DEFAULT NULL,
  `Away_End` DATETIME DEFAULT NULL,
  `Balance` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `Created_At` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Updated_At` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `users_email_unique` (`Email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `promos` (
  `IdPromo` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `PromoCode` VARCHAR(100) NOT NULL,
  `Date_Expire` DATETIME NOT NULL,
  `Number_Use` INT NOT NULL DEFAULT 0,
  `Discounted_Price` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `Created_At` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`IdPromo`),
  UNIQUE KEY `promos_code_unique` (`PromoCode`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `orders` (
  `idOrder` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `idUser` INT UNSIGNED NOT NULL,
  `Id_Reshipper` INT UNSIGNED NOT NULL,
  `Notes` TEXT,
  `Date_Expected` DATE DEFAULT NULL,
  `Date_Accept` DATE DEFAULT NULL,
  `Name_on_Parcel` VARCHAR(255) DEFAULT NULL,
  `Quantity` INT DEFAULT NULL,
  `Tracking_Number` VARCHAR(255) DEFAULT NULL,
  `Courier` VARCHAR(255) DEFAULT NULL,
  `Price` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `Accept_Status` ENUM('True','False') NOT NULL DEFAULT 'False',
  `Status` VARCHAR(50) NOT NULL DEFAULT 'Processing',
  `ImageLink` VARCHAR(1024) DEFAULT NULL,
  `Created_At` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`idOrder`),
  KEY `orders_user_idx` (`idUser`),
  KEY `orders_reshipper_idx` (`Id_Reshipper`),
  CONSTRAINT `orders_user_fk` FOREIGN KEY (`idUser`) REFERENCES `users` (`Id`) ON DELETE CASCADE,
  CONSTRAINT `orders_reshipper_fk` FOREIGN KEY (`Id_Reshipper`) REFERENCES `users` (`Id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `notifications` (
  `idNotification` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `IdUser` INT UNSIGNED NOT NULL,
  `TitleNotification` VARCHAR(255) NOT NULL,
  `Notification` TEXT NOT NULL,
  `ImageNotification` VARCHAR(1024) DEFAULT NULL,
  `DateNotification` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`idNotification`),
  KEY `notifications_user_idx` (`IdUser`),
  CONSTRAINT `notifications_user_fk` FOREIGN KEY (`IdUser`) REFERENCES `users` (`Id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `climedaddress` (
  `iduser` INT UNSIGNED NOT NULL,
  `Id_Cliemd` INT UNSIGNED NOT NULL,
  `Created_At` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`iduser`, `Id_Cliemd`),
  CONSTRAINT `climedaddress_user_fk` FOREIGN KEY (`iduser`) REFERENCES `users` (`Id`) ON DELETE CASCADE,
  CONSTRAINT `climedaddress_reshipper_fk` FOREIGN KEY (`Id_Cliemd`) REFERENCES `users` (`Id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `payments` (
  `idPayment` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `idUser` INT UNSIGNED NOT NULL,
  `idReshipper` INT UNSIGNED DEFAULT NULL,
  `idOrder` INT UNSIGNED DEFAULT NULL,
  `Type` VARCHAR(50) DEFAULT 'Parcel',
  `paymentPrice` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `priceAfterFees` DECIMAL(12,2) DEFAULT NULL,
  `datePayment` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`idPayment`),
  KEY `payments_user_idx` (`idUser`),
  KEY `payments_reshipper_idx` (`idReshipper`),
  KEY `payments_order_idx` (`idOrder`),
  CONSTRAINT `payments_user_fk` FOREIGN KEY (`idUser`) REFERENCES `users` (`Id`) ON DELETE CASCADE,
  CONSTRAINT `payments_reshipper_fk` FOREIGN KEY (`idReshipper`) REFERENCES `users` (`Id`) ON DELETE SET NULL,
  CONSTRAINT `payments_order_fk` FOREIGN KEY (`idOrder`) REFERENCES `orders` (`idOrder`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `totalprofit` (
  `idProfit` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `idUser` INT UNSIGNED NOT NULL,
  `idOrder` INT UNSIGNED DEFAULT NULL,
  `profitPrice` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `note` VARCHAR(255) DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`idProfit`),
  KEY `totalprofit_user_idx` (`idUser`),
  KEY `totalprofit_order_idx` (`idOrder`),
  CONSTRAINT `totalprofit_user_fk` FOREIGN KEY (`idUser`) REFERENCES `users` (`Id`) ON DELETE CASCADE,
  CONSTRAINT `totalprofit_order_fk` FOREIGN KEY (`idOrder`) REFERENCES `orders` (`idOrder`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
