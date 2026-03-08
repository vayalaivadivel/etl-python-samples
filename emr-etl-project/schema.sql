CREATE DATABASE IF NOT EXISTS etldb;

USE etldb;

CREATE TABLE IF NOT EXISTS companies (
    `_input` VARCHAR(255),
    `_num` INT,
    `_widgetName` VARCHAR(255),
    `_source` VARCHAR(255),
    `_resultNumber` INT,
    `_pageUrl` TEXT,
    `id` INT PRIMARY KEY,
    `rank` INT,
    `workers` INT,
    `company` VARCHAR(255),
    `url` TEXT,
    `state_l` VARCHAR(100),
    `state_s` VARCHAR(10),
    `city` VARCHAR(100),
    `metro` VARCHAR(100),
    `growth` DECIMAL(15,2),
    `revenue` VARCHAR(100),
    `industry` VARCHAR(255),
    `yrs_on_list` INT
);