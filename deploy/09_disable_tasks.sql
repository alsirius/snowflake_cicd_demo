-- =============================================================================
-- 09_DISABLE_TASKS.SQL
-- Disables all tasks (for cleanup or maintenance)
-- =============================================================================

-- Config loaded from 00_env_config.sql
USE DATABASE IDENTIFIER($DB_NAME);

-- Disable in reverse order (parent first, then children)
ALTER TASK INT.TASK_MERGE_DIM_SITE SUSPEND;
ALTER TASK INT.TASK_MERGE_FACT_VISITS SUSPEND;
ALTER TASK RAW.TASK_GENERATE_DEMO_DATA SUSPEND;

SELECT 'All tasks suspended for ' || $DB_NAME AS status;
