-- =============================================================================
-- 08_ENABLE_TASKS.SQL
-- Enables all tasks and runs initial data generation
-- Run this AFTER all other deploy scripts
-- =============================================================================

-- Config loaded from 00_env_config.sql
USE DATABASE IDENTIFIER($DB_NAME);

-- Enable pipeline tasks (order matters: child first, then parent)
ALTER TASK INT.TASK_MERGE_FACT_VISITS RESUME;
ALTER TASK INT.TASK_MERGE_DIM_SITE RESUME;

-- Enable data generator task (for live demo)
ALTER TASK RAW.TASK_GENERATE_DEMO_DATA RESUME;

-- Run initial data generation
CALL RAW.GENERATE_DEMO_DATA(30);

-- Execute pipeline immediately
EXECUTE TASK INT.TASK_MERGE_DIM_SITE;

SELECT 'Tasks enabled and initial data loaded for ' || $DB_NAME AS status;
