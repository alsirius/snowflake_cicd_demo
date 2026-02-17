-- =============================================================================
-- 07_CREATE_DATA_GENERATOR.SQL
-- Creates data generator procedure and task for demo purposes
-- Generates new sample data each time executed to demonstrate stream/task flow
-- =============================================================================

-- Config loaded from 00_env_config.sql
USE DATABASE IDENTIFIER($DB_NAME);

-- Procedure: Generate sample site data (initial seed)
CREATE OR REPLACE PROCEDURE RAW.GENERATE_SEED_SITES()
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
BEGIN
    INSERT INTO RAW.SITE_DIM_RAW (
        SHOPPERTRAK_SITE_ID, SITE_NAME, BOROUGH, ADDRESS, CITY, STATE, POSTCODE, LAT, LON, SITE_CATEGORY, _RAW_HASH
    )
    SELECT
        'NY_LIB_' || LPAD(seq4()::STRING, 3, '0') AS SHOPPERTRAK_SITE_ID,
        'Library Branch ' || LPAD(seq4()::STRING, 3, '0') AS SITE_NAME,
        borough, address, 'New York' AS CITY, 'NY' AS STATE, postcode, lat, lon,
        'Library' AS SITE_CATEGORY,  -- NEW: Category for all library sites
        MD5('NY_LIB_' || LPAD(seq4()::STRING, 3, '0') || '|' || borough || '|' || lat::STRING || '|' || lon::STRING) AS _RAW_HASH
    FROM (
        SELECT column1::STRING AS borough, column2::STRING AS address, column3::STRING AS postcode,
               column4::NUMBER(9,6) AS lat, column5::NUMBER(9,6) AS lon
        FROM VALUES
            ('Manhattan', '476 5th Ave', '10018', 40.753182, -73.982253),
            ('Manhattan', '10 E 53rd St', '10022', 40.760092, -73.975496),
            ('Manhattan', '455 5th Ave', '10016', 40.751620, -73.981920),
            ('Brooklyn', '10 Grand Army Plz', '11238', 40.672501, -73.968056),
            ('Brooklyn', '1488 Hertel Ave', '11219', 40.634500, -73.996000),
            ('Queens', '89-11 Merrick Blvd', '11432', 40.707420, -73.794040),
            ('Queens', '41-17 Main St', '11355', 40.759600, -73.830300),
            ('Bronx', '310 E Kingsbridge', '10458', 40.867900, -73.894600),
            ('Bronx', '9 W Fordham Rd', '10468', 40.861500, -73.897100),
            ('Staten Island', '5 Central Ave', '10301', 40.642400, -74.076000),
            ('Manhattan', '200 W 53rd St', '10019', 40.763800, -73.983200),
            ('Brooklyn', '286 Cadman Plaza', '11201', 40.695200, -73.990300)
    ) s
    WHERE NOT EXISTS (
        SELECT 1 FROM RAW.SITE_DIM_RAW WHERE SHOPPERTRAK_SITE_ID = 'NY_LIB_' || LPAD(seq4()::STRING, 3, '0')
    );
    RETURN 'Seed sites generated at ' || CURRENT_TIMESTAMP();
END;
$$;

-- Procedure: Generate incremental visit data (for demo)
CREATE OR REPLACE PROCEDURE RAW.GENERATE_INCREMENTAL_VISITS(HOURS_TO_GENERATE INT DEFAULT 24)
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
DECLARE
    rows_inserted INT;
BEGIN
    INSERT INTO RAW.HOURLY_VISITS_RAW (
        SHOPPERTRAK_SITE_ID, ORBIT, INCREMENT_DATE, INCREMENT_HOUR, ENTERS, EXITS,
        _IS_HEALTHY, _SOURCE_FILE, _RAW_HASH
    )
    WITH sites AS (
        SELECT SHOPPERTRAK_SITE_ID FROM RAW.SITE_DIM_RAW
    ),
    hours AS (
        SELECT 
            DATEADD('hour', -seq4(), CURRENT_TIMESTAMP()) AS ts,
            DATE(DATEADD('hour', -seq4(), CURRENT_TIMESTAMP())) AS d,
            HOUR(DATEADD('hour', -seq4(), CURRENT_TIMESTAMP())) AS h
        FROM TABLE(GENERATOR(ROWCOUNT => :HOURS_TO_GENERATE))
    ),
    base AS (
        SELECT
            s.SHOPPERTRAK_SITE_ID,
            UNIFORM(1, 5, RANDOM())::INT AS ORBIT,
            hr.d AS INCREMENT_DATE,
            hr.h AS INCREMENT_HOUR,
            GREATEST(0, ROUND(
                CASE
                    WHEN hr.h BETWEEN 8 AND 10 THEN 25
                    WHEN hr.h BETWEEN 11 AND 16 THEN 70
                    WHEN hr.h BETWEEN 17 AND 19 THEN 45
                    ELSE 10
                END + UNIFORM(-10, 30, RANDOM())
            ))::INT AS ENTERS_RAW
        FROM sites s
        CROSS JOIN hours hr
    )
    SELECT
        SHOPPERTRAK_SITE_ID, ORBIT, INCREMENT_DATE, INCREMENT_HOUR,
        ENTERS_RAW AS ENTERS,
        LEAST(ENTERS_RAW, GREATEST(0, ENTERS_RAW - UNIFORM(0, 15, RANDOM())::INT)) AS EXITS,
        IFF(UNIFORM(1,100,RANDOM()) <= 98, TRUE, FALSE) AS _IS_HEALTHY,
        'DEMO_GENERATOR_' || TO_VARCHAR(CURRENT_TIMESTAMP(), 'YYYYMMDDHH24MISS') AS _SOURCE_FILE,
        MD5(SHOPPERTRAK_SITE_ID || '|' || ORBIT::STRING || '|' || INCREMENT_DATE::STRING || '|' || 
            INCREMENT_HOUR::STRING || '|' || ENTERS_RAW::STRING || '|' || RANDOM()::STRING) AS _RAW_HASH
    FROM base;
    
    rows_inserted := SQLROWCOUNT;
    RETURN 'Generated ' || rows_inserted || ' visit records at ' || CURRENT_TIMESTAMP();
END;
$$;

-- Procedure: Full data generation (combines seed + visits)
CREATE OR REPLACE PROCEDURE RAW.GENERATE_DEMO_DATA(DAYS_BACK INT DEFAULT 30)
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
DECLARE
    result STRING;
BEGIN
    CALL RAW.GENERATE_SEED_SITES();
    CALL RAW.GENERATE_INCREMENTAL_VISITS(:DAYS_BACK * 24);
    RETURN 'Demo data generated: ' || :DAYS_BACK || ' days of visits at ' || CURRENT_TIMESTAMP();
END;
$$;

-- Task: Auto-generate new data every 5 minutes (for live demo)
CREATE OR REPLACE TASK RAW.TASK_GENERATE_DEMO_DATA
    WAREHOUSE = IDENTIFIER($WH_NAME)
    SCHEDULE = 'USING CRON */5 * * * * UTC'
AS
    CALL RAW.GENERATE_INCREMENTAL_VISITS(1);

-- Keep suspended by default
ALTER TASK RAW.TASK_GENERATE_DEMO_DATA SUSPEND;

SELECT 'Data generator created for ' || $DB_NAME AS status;
