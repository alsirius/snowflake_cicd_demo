-- Environment Configuration Template
-- Usage: Set session variables before running deploy scripts
-- Example: SET ENV = 'DEV'; SET DB_PREFIX = 'DEV';

-- Environment: DEV | TEST | PROD
SET ENV = 'DEV';

-- Database naming convention: {PREFIX}_VISIT_DEMO_DB
SET DB_PREFIX = 'DEV';

-- Warehouse sizing by environment
SET WH_SIZE = CASE 
    WHEN $ENV = 'PROD' THEN 'SMALL'
    WHEN $ENV = 'TEST' THEN 'XSMALL'
    ELSE 'XSMALL'
END;

-- Auto-suspend settings (seconds)
SET AUTO_SUSPEND = CASE
    WHEN $ENV = 'PROD' THEN 120
    ELSE 60
END;
