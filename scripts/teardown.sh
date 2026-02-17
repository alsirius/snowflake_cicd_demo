#!/bin/bash
# =============================================================================
# TEARDOWN.SH
# Cleanup script to remove all demo objects
# Usage: ./scripts/teardown.sh [DEV|TEST|PROD]
# =============================================================================

set -e

ENV=${1:-DEV}
DB_PREFIX=$ENV
DB_NAME="${DB_PREFIX}_VISIT_DEMO_17F_DB"
WH_NAME="${DB_PREFIX}_VISIT_DEMO_17F_WH"

echo "=========================================="
echo "⚠️  TEARDOWN: Removing $ENV environment"
echo "Database: $DB_NAME"
echo "Warehouse: $WH_NAME"
echo "=========================================="

read -p "Are you sure you want to delete all objects? (yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
    echo "Aborted."
    exit 0
fi

snowsql -q "
    -- Suspend tasks first
    ALTER TASK IF EXISTS ${DB_NAME}.INT.TASK_MERGE_DIM_SITE SUSPEND;
    ALTER TASK IF EXISTS ${DB_NAME}.INT.TASK_MERGE_FACT_VISITS SUSPEND;
    ALTER TASK IF EXISTS ${DB_NAME}.RAW.TASK_GENERATE_DEMO_DATA SUSPEND;
    
    -- Drop database (includes all schemas, tables, views, procedures, tasks)
    DROP DATABASE IF EXISTS ${DB_NAME};
    
    -- Drop warehouse
    DROP WAREHOUSE IF EXISTS ${WH_NAME};
"

echo "=========================================="
echo "✅ Teardown of $ENV complete!"
echo "=========================================="
