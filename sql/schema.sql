-- =====================================================================
-- Track-IA RP Framework — Database Schema
-- Engine: MySQL 8+ / MariaDB 10.5+
-- Charset: utf8mb4 (emoji / accents support for phone, chat, names)
-- =====================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ---------------------------------------------------------------------
-- players : one row per Rockstar/FiveM identity (account level, not char)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `players` (
  `identifier`   VARCHAR(60)  NOT NULL,           -- license:xxxx (primary account key)
  `discord`      VARCHAR(30)  DEFAULT NULL,
  `steam`        VARCHAR(30)  DEFAULT NULL,
  `name`         VARCHAR(100) NOT NULL DEFAULT '',
  `first_seen`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_seen`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `playtime_min` INT UNSIGNED NOT NULL DEFAULT 0,
  `donator_tier` TINYINT UNSIGNED NOT NULL DEFAULT 0,  -- 0=none,1=bronze,2=silver,3=gold (monetization hook)
  `banned`       TINYINT(1)   NOT NULL DEFAULT 0,
  `ban_reason`   VARCHAR(255) DEFAULT NULL,
  `ban_expire`   DATETIME     DEFAULT NULL,          -- NULL = permanent
  `whitelisted`  TINYINT(1)   NOT NULL DEFAULT 0,
  PRIMARY KEY (`identifier`),
  KEY `idx_players_discord` (`discord`),
  KEY `idx_players_banned` (`banned`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- characters : multichar slots, the actual RP persona
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `characters` (
  `citizenid`   VARCHAR(20)  NOT NULL,             -- short public id, e.g. ABC12345
  `identifier`  VARCHAR(60)  NOT NULL,
  `slot`        TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `firstname`   VARCHAR(50)  NOT NULL,
  `lastname`    VARCHAR(50)  NOT NULL,
  `birthdate`   VARCHAR(10)  NOT NULL DEFAULT '2000-01-01',
  `gender`      TINYINT UNSIGNED NOT NULL DEFAULT 0,   -- 0=male,1=female
  `nationality` VARCHAR(50)  NOT NULL DEFAULT 'USA',
  `phone_number`VARCHAR(15)  DEFAULT NULL,
  `cash`        BIGINT UNSIGNED NOT NULL DEFAULT 500,
  `bank`        BIGINT UNSIGNED NOT NULL DEFAULT 2500,
  `job`         VARCHAR(50)  NOT NULL DEFAULT 'unemployed',
  `job_grade`   TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `job_onduty`  TINYINT(1)   NOT NULL DEFAULT 0,
  `gang`        VARCHAR(50)  NOT NULL DEFAULT 'none',
  `gang_grade`  TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `position`    JSON         DEFAULT NULL,          -- {x,y,z,heading,dimension}
  `metadata`    JSON         DEFAULT NULL,          -- {health,armor,hunger,thirst,stress,dead,...}
  `skin`        JSON         DEFAULT NULL,          -- ped appearance model data
  `is_dead`     TINYINT(1)   NOT NULL DEFAULT 0,
  `last_seen`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `deleted`     TINYINT(1)   NOT NULL DEFAULT 0,
  PRIMARY KEY (`citizenid`),
  UNIQUE KEY `uniq_phone` (`phone_number`),
  KEY `idx_char_identifier` (`identifier`),
  KEY `idx_char_job` (`job`),
  CONSTRAINT `fk_char_identifier` FOREIGN KEY (`identifier`)
    REFERENCES `players` (`identifier`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- inventories : slot-based storage for ANY container (player, trunk,
-- glovebox, stash, shop-drop). `owner_id` is a generic string key so
-- one table serves every inventory type — avoids N join tables.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `inventories` (
  `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `owner_id`   VARCHAR(60)  NOT NULL,   -- citizenid | 'trunk-<PLATE>' | 'glove-<PLATE>' | 'stash-<id>'
  `owner_type` VARCHAR(20)  NOT NULL,   -- player | trunk | glovebox | stash | drop
  `slot`       SMALLINT UNSIGNED NOT NULL,
  `item`       VARCHAR(60)  NOT NULL,
  `amount`     INT UNSIGNED NOT NULL DEFAULT 1,
  `metadata`   JSON         DEFAULT NULL,   -- durability, serial number, ammo type, quality...
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_owner_slot` (`owner_id`, `slot`),
  KEY `idx_inv_owner` (`owner_id`, `owner_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- bank_transactions : full audit trail (required for anti-dupe & support)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `bank_transactions` (
  `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `citizenid`   VARCHAR(20)  NOT NULL,
  `type`        ENUM('deposit','withdraw','transfer_out','transfer_in','salary','fine','invoice','admin') NOT NULL,
  `amount`      BIGINT UNSIGNED NOT NULL,
  `balance_after` BIGINT UNSIGNED NOT NULL,
  `note`        VARCHAR(255) DEFAULT NULL,
  `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_tx_citizen` (`citizenid`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- vehicles : player-owned vehicles
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `vehicles` (
  `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `plate`      VARCHAR(12)  NOT NULL,
  `citizenid`  VARCHAR(20)  NOT NULL,
  `model`      VARCHAR(60)  NOT NULL,
  `garage`     VARCHAR(50)  NOT NULL DEFAULT 'legion',
  `state`      ENUM('garaged','out','impound') NOT NULL DEFAULT 'garaged',
  `fuel`       TINYINT UNSIGNED NOT NULL DEFAULT 100,
  `engine`     SMALLINT UNSIGNED NOT NULL DEFAULT 1000,
  `body`       SMALLINT UNSIGNED NOT NULL DEFAULT 1000,
  `mods`       JSON         DEFAULT NULL,
  `financed`   INT UNSIGNED NOT NULL DEFAULT 0,     -- remaining loan balance (monetization: financing)
  `impound_fee` INT UNSIGNED NOT NULL DEFAULT 0,
  `created_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_plate` (`plate`),
  KEY `idx_veh_owner` (`citizenid`),
  CONSTRAINT `fk_veh_owner` FOREIGN KEY (`citizenid`)
    REFERENCES `characters` (`citizenid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- properties : housing
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `properties` (
  `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `label`      VARCHAR(100) NOT NULL,
  `coords`     JSON         NOT NULL,     -- {x,y,z,heading}
  `interior_coords` JSON    DEFAULT NULL,
  `price`      INT UNSIGNED NOT NULL DEFAULT 50000,
  `tier`       TINYINT UNSIGNED NOT NULL DEFAULT 1,   -- shell tier -> interior/decor tier
  `owner_citizenid` VARCHAR(20) DEFAULT NULL,
  `stash_id`   VARCHAR(60)  NOT NULL,     -- links to inventories.owner_id ('stash-<id>')
  `locked`     TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `idx_prop_owner` (`owner_citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- phone_contacts / phone_messages : lightweight in-house phone
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `phone_contacts` (
  `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `citizenid`  VARCHAR(20)  NOT NULL,
  `name`       VARCHAR(60)  NOT NULL,
  `number`     VARCHAR(15)  NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_contact_owner` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `phone_messages` (
  `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `sender`     VARCHAR(15)  NOT NULL,
  `receiver`   VARCHAR(15)  NOT NULL,
  `message`    VARCHAR(500) NOT NULL,
  `sent_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_msg_thread` (`sender`, `receiver`),
  KEY `idx_msg_receiver` (`receiver`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- admin / moderation / anti-cheat logs
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `admin_logs` (
  `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `admin_identifier` VARCHAR(60) DEFAULT NULL,
  `target_identifier` VARCHAR(60) DEFAULT NULL,
  `action`      VARCHAR(40)  NOT NULL,   -- ban, kick, give, teleport, noclip_flag, etc.
  `details`     VARCHAR(255) DEFAULT NULL,
  `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_alog_target` (`target_identifier`),
  KEY `idx_alog_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `anticheat_flags` (
  `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `identifier`  VARCHAR(60)  NOT NULL,
  `citizenid`   VARCHAR(20)  DEFAULT NULL,
  `type`        VARCHAR(40)  NOT NULL,   -- speed, noclip, weapon, money, teleport, godmode
  `details`     VARCHAR(255) DEFAULT NULL,
  `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_flag_identifier` (`identifier`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- sample properties (edit freely — this is just enough to launch with)
-- ---------------------------------------------------------------------
INSERT INTO `properties` (`id`, `label`, `coords`, `price`, `tier`, `stash_id`) VALUES
  (1, 'Studio - Legion Square',      '{"x": 200.5, "y": -800.2, "z": 31.0, "heading": 90.0}',  35000,  1, 'stash-1'),
  (2, 'Appartement - Vespucci',      '{"x": -1090.0, "y": -880.0, "z": 3.0, "heading": 180.0}', 68000,  2, 'stash-2'),
  (3, 'Maison - Vinewood Hills',     '{"x": 100.0, "y": 550.0, "z": 190.0, "heading": 45.0}',   250000, 3, 'stash-3'),
  (4, 'Villa - Rockford Hills',      '{"x": -800.0, "y": 150.0, "z": 65.0, "heading": 0.0}',    620000, 4, 'stash-4')
ON DUPLICATE KEY UPDATE label = VALUES(label);

SET FOREIGN_KEY_CHECKS = 1;
