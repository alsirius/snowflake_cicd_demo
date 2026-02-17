-- =============================================================================
-- 00_ENV_CONFIG.SQL
-- CENTRALIZED CONFIGURATION - All naming conventions defined here
-- This file is sourced by all other deploy scripts
-- =============================================================================

-- Database and Warehouse naming (CHANGE THESE FOR YOUR PROJECT)
SET DB_SUFFIX = '_VISIT_DEMO_17F_DB';
SET WH_SUFFIX = '_VISIT_DEMO_17F_WH';

-- Derived names (uses DB_PREFIX passed from CLI: -D DB_PREFIX=DEV)
SET DB_NAME = '&DB_PREFIX' || $DB_SUFFIX;
SET WH_NAME = '&DB_PREFIX' || $WH_SUFFIX;

-- Environment-specific settings
SET WH_SIZE = CASE 
    WHEN '&DB_PREFIX' = 'PROD' THEN 'SMALL'
    WHEN '&DB_PREFIX' = 'TEST' THEN 'XSMALL'
    ELSE 'XSMALL'
END;

SET AUTO_SUSPEND = CASE
    WHEN '&DB_PREFIX' = 'PROD' THEN 120
    ELSE 60
END;
