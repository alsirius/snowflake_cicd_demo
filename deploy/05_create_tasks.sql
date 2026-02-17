-- =============================================================================
-- 05_CREATE_TASKS.SQL
-- Creates tasks for automated pipeline execution
-- =============================================================================

-- Config loaded from 00_env_config.sql
USE DATABASE IDENTIFIER($DB_NAME);

-- Task: Process site dimension (runs when stream has data)
CREATE OR REPLACE TASK INT.TASK_MERGE_DIM_SITE
    WAREHOUSE = IDENTIFIER($WH_NAME)
    SCHEDULE = 'USING CRON 0 * * * * UTC'
    WHEN SYSTEM$STREAM_HAS_DATA('RAW.SITE_DIM_RAW_STREAM')
AS
    CALL INT.MERGE_DIM_SITE();

-- Task: Process fact visits (runs after dimension task)
CREATE OR REPLACE TASK INT.TASK_MERGE_FACT_VISITS
    WAREHOUSE = IDENTIFIER($WH_NAME)
    AFTER INT.TASK_MERGE_DIM_SITE
AS
    CALL INT.MERGE_FACT_VISITS();

-- Initially suspend tasks (enable via 08_enable_tasks.sql)
ALTER TASK INT.TASK_MERGE_FACT_VISITS SUSPEND;
ALTER TASK INT.TASK_MERGE_DIM_SITE SUSPEND;

SELECT 'Tasks created (suspended) for ' || $DB_NAME AS status;
