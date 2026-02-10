-- =============================================================================
-- TEST_DATA_QUALITY.SQL
-- Data quality tests for the pipeline
-- =============================================================================

SET DB_NAME = $DB_PREFIX || '_VISIT_DEMO_DB';
USE DATABASE IDENTIFIER($DB_NAME);

-- DQ Test 1: No negative values in visits
SELECT CASE 
    WHEN COUNT(*) = 0 THEN 'PASS: No negative ENTERS values'
    ELSE 'FAIL: Found ' || COUNT(*) || ' negative ENTERS values'
END AS dq_no_negative_enters
FROM RAW.HOURLY_VISITS_RAW WHERE ENTERS < 0;

SELECT CASE 
    WHEN COUNT(*) = 0 THEN 'PASS: No negative EXITS values'
    ELSE 'FAIL: Found ' || COUNT(*) || ' negative EXITS values'
END AS dq_no_negative_exits
FROM RAW.HOURLY_VISITS_RAW WHERE EXITS < 0;

-- DQ Test 2: Valid hour range
SELECT CASE 
    WHEN COUNT(*) = 0 THEN 'PASS: All hours in valid range (0-23)'
    ELSE 'FAIL: Found ' || COUNT(*) || ' records with invalid hours'
END AS dq_valid_hours
FROM RAW.HOURLY_VISITS_RAW 
WHERE INCREMENT_HOUR < 0 OR INCREMENT_HOUR > 23;

-- DQ Test 3: No null required fields in RAW
SELECT CASE 
    WHEN COUNT(*) = 0 THEN 'PASS: No null SHOPPERTRAK_SITE_ID in visits'
    ELSE 'FAIL: Found ' || COUNT(*) || ' null SHOPPERTRAK_SITE_ID'
END AS dq_no_null_site_id
FROM RAW.HOURLY_VISITS_RAW WHERE SHOPPERTRAK_SITE_ID IS NULL;

-- DQ Test 4: Referential integrity (all visits have a site)
SELECT CASE 
    WHEN COUNT(*) = 0 THEN 'PASS: All visits have matching sites'
    ELSE 'WARN: Found ' || COUNT(*) || ' visits without matching site'
END AS dq_referential_integrity
FROM INT.FACT_HOURLY_VISITS f
LEFT JOIN INT.DIM_SITE d ON f.SHOPPERTRAK_SITE_ID = d.SHOPPERTRAK_SITE_ID
WHERE d.SHOPPERTRAK_SITE_ID IS NULL;

-- DQ Test 5: No duplicate primary keys in FACT
SELECT CASE 
    WHEN COUNT(*) = 0 THEN 'PASS: No duplicate keys in FACT_HOURLY_VISITS'
    ELSE 'FAIL: Found ' || COUNT(*) || ' duplicate key combinations'
END AS dq_no_duplicate_fact_keys
FROM (
    SELECT SHOPPERTRAK_SITE_ID, INCREMENT_DATE, INCREMENT_HOUR, COUNT(*) as cnt
    FROM INT.FACT_HOURLY_VISITS
    GROUP BY 1,2,3
    HAVING COUNT(*) > 1
);

-- DQ Test 6: Hash values populated
SELECT CASE 
    WHEN COUNT(*) = 0 THEN 'PASS: All RAW records have hash values'
    ELSE 'FAIL: Found ' || COUNT(*) || ' records without hash'
END AS dq_hash_populated
FROM RAW.HOURLY_VISITS_RAW WHERE _RAW_HASH IS NULL;

-- DQ Test 7: Load timestamp populated
SELECT CASE 
    WHEN COUNT(*) = 0 THEN 'PASS: All records have load timestamps'
    ELSE 'FAIL: Found ' || COUNT(*) || ' records without load timestamp'
END AS dq_timestamp_populated
FROM RAW.HOURLY_VISITS_RAW WHERE _LOAD_TS IS NULL;

-- DQ Test 8: Reasonable date range (not future, not too old)
SELECT CASE 
    WHEN COUNT(*) = 0 THEN 'PASS: All dates within reasonable range'
    ELSE 'WARN: Found ' || COUNT(*) || ' records with suspicious dates'
END AS dq_reasonable_dates
FROM RAW.HOURLY_VISITS_RAW 
WHERE INCREMENT_DATE > CURRENT_DATE() + 1 
   OR INCREMENT_DATE < DATEADD('year', -2, CURRENT_DATE());

SELECT '=== DATA QUALITY TESTS COMPLETED ===' AS dq_summary;
