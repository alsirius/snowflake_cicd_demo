-- =============================================================================
-- 01_SETUP_INFRASTRUCTURE.SQL
-- Creates database, schemas, and warehouse for the target environment
-- Run with: snowsql -f 01_setup_infrastructure.sql -D ENV=DEV -D DB_PREFIX=DEV
-- =============================================================================

-- Config loaded from 00_env_config.sql - no need to set DB_NAME/WH_NAME here

CREATE DATABASE IF NOT EXISTS IDENTIFIER($DB_NAME);
USE DATABASE IDENTIFIER($DB_NAME);

CREATE SCHEMA IF NOT EXISTS COMMON;
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS INT;
CREATE SCHEMA IF NOT EXISTS PRS;

CREATE WAREHOUSE IF NOT EXISTS IDENTIFIER($WH_NAME)
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

SELECT 'Infrastructure setup complete for ' || $DB_NAME AS status;
