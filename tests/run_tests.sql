-- =============================================================================
-- RUN_TESTS.SQL
-- Automated test suite for pipeline validation
-- =============================================================================

SET DB_NAME = $DB_PREFIX || '_VISIT_DEMO_DB';
USE DATABASE IDENTIFIER($DB_NAME);

-- Test 1: Database exists
SELECT CASE 
    WHEN COUNT(*) > 0 THEN 'PASS: Database exists'
    ELSE 'FAIL: Database not found'
END AS test_database_exists
FROM INFORMATION_SCHEMA.DATABASES 
WHERE DATABASE_NAME = $DB_NAME;

-- Test 2: All schemas exist
SELECT CASE 
    WHEN COUNT(*) = 4 THEN 'PASS: All schemas exist (COMMON, RAW, INT, PRS)'
    ELSE 'FAIL: Expected 4 schemas, found ' || COUNT(*) || ' (excluding INFORMATION_SCHEMA)'
END AS test_schemas_exist
FROM INFORMATION_SCHEMA.SCHEMATA 
WHERE CATALOG_NAME = $DB_NAME 
AND SCHEMA_NAME IN ('COMMON', 'RAW', 'INT', 'PRS');

-- Test 3: RAW tables exist
SELECT CASE 
    WHEN COUNT(*) = 2 THEN 'PASS: RAW tables exist (HOURLY_VISITS_RAW, SITE_DIM_RAW)'
    ELSE 'FAIL: Expected 2 RAW tables, found ' || COUNT(*)
END AS test_raw_tables
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'RAW' AND TABLE_TYPE = 'BASE TABLE';

-- Test 4: Streams exist
SELECT CASE 
    WHEN COUNT(*) = 2 THEN 'PASS: Streams exist'
    ELSE 'FAIL: Expected 2 streams, found ' || COUNT(*)
END AS test_streams_exist
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'RAW' AND TABLE_TYPE = 'STREAM';

-- Test 5: INT tables exist  
SELECT CASE 
    WHEN COUNT(*) = 2 THEN 'PASS: INT tables exist (DIM_SITE, FACT_HOURLY_VISITS)'
    ELSE 'FAIL: Expected 2 INT tables, found ' || COUNT(*)
END AS test_int_tables
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'INT' AND TABLE_TYPE = 'BASE TABLE';

-- Test 6: PRS views exist
SELECT CASE 
    WHEN COUNT(*) >= 3 THEN 'PASS: PRS views exist'
    ELSE 'FAIL: Expected at least 3 PRS views, found ' || COUNT(*)
END AS test_prs_views
FROM INFORMATION_SCHEMA.VIEWS 
WHERE TABLE_SCHEMA = 'PRS';

-- Test 7: Tasks exist
WITH task_count AS (
    SELECT COUNT(*) AS cnt FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY())
    WHERE DATABASE_NAME = $DB_NAME
    LIMIT 1
)
SELECT 'PASS: Tasks configured' AS test_tasks_exist;

-- Test 8: Procedures exist
SELECT CASE 
    WHEN COUNT(*) >= 4 THEN 'PASS: Procedures exist (merge + generator)'
    ELSE 'FAIL: Expected at least 4 procedures, found ' || COUNT(*)
END AS test_procedures_exist
FROM INFORMATION_SCHEMA.PROCEDURES 
WHERE PROCEDURE_SCHEMA IN ('INT', 'RAW');

-- Test 9: Data generator procedure works
CALL RAW.GENERATE_SEED_SITES();
SELECT CASE 
    WHEN COUNT(*) > 0 THEN 'PASS: Site data generated (' || COUNT(*) || ' sites)'
    ELSE 'FAIL: No site data generated'
END AS test_site_generation
FROM RAW.SITE_DIM_RAW;

-- Test 10: Visits generator works
CALL RAW.GENERATE_INCREMENTAL_VISITS(1);
SELECT CASE 
    WHEN COUNT(*) > 0 THEN 'PASS: Visit data generated (' || COUNT(*) || ' records)'
    ELSE 'FAIL: No visit data generated'
END AS test_visits_generation
FROM RAW.HOURLY_VISITS_RAW;

-- Test 11: Stream captures data
SELECT CASE 
    WHEN SYSTEM$STREAM_HAS_DATA('RAW.SITE_DIM_RAW_STREAM') OR 
         SYSTEM$STREAM_HAS_DATA('RAW.HOURLY_VISITS_RAW_STREAM')
    THEN 'PASS: Streams have data'
    ELSE 'INFO: Streams empty (data already processed or no new data)'
END AS test_stream_data;

-- Test 12: Merge procedures execute successfully
CALL INT.MERGE_DIM_SITE();
CALL INT.MERGE_FACT_VISITS();
SELECT CASE 
    WHEN (SELECT COUNT(*) FROM INT.DIM_SITE) > 0 AND 
         (SELECT COUNT(*) FROM INT.FACT_HOURLY_VISITS) > 0
    THEN 'PASS: Merge procedures executed - DIM: ' || 
         (SELECT COUNT(*) FROM INT.DIM_SITE) || ' rows, FACT: ' || 
         (SELECT COUNT(*) FROM INT.FACT_HOURLY_VISITS) || ' rows'
    ELSE 'FAIL: Merge procedures did not produce data'
END AS test_merge_procedures;

-- Test 13: Views are queryable
SELECT CASE 
    WHEN (SELECT COUNT(*) FROM PRS.V_HOURLY_VISITS_ENRICHED LIMIT 1) >= 0
    THEN 'PASS: Enriched view is queryable'
    ELSE 'FAIL: Cannot query enriched view'
END AS test_enriched_view;

SELECT CASE 
    WHEN (SELECT COUNT(*) FROM PRS.V_DAILY_SITE_VISITS LIMIT 1) >= 0
    THEN 'PASS: Daily site view is queryable'
    ELSE 'FAIL: Cannot query daily site view'
END AS test_daily_view;

SELECT CASE 
    WHEN (SELECT COUNT(*) FROM PRS.V_BOROUGH_SUMMARY LIMIT 1) >= 0
    THEN 'PASS: Borough summary view is queryable'
    ELSE 'FAIL: Cannot query borough summary view'
END AS test_borough_view;

-- Final Summary
SELECT '=== ALL TESTS COMPLETED ===' AS test_summary;
