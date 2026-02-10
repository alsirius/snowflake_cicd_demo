#!/bin/bash
# =============================================================================
# DEPLOY.SH
# Master deployment script for local or CI/CD execution
# Usage: ./scripts/deploy.sh [DEV|TEST|PROD]
# =============================================================================

set -e

ENV=${1:-DEV}
DB_PREFIX=$ENV

echo "=========================================="
echo "Deploying Visit Demo Pipeline to $ENV"
echo "Database: ${DB_PREFIX}_VISIT_DEMO_DB"
echo "=========================================="

# Validate environment
if [[ ! "$ENV" =~ ^(DEV|TEST|PROD)$ ]]; then
    echo "Error: Invalid environment. Use DEV, TEST, or PROD"
    exit 1
fi

# Check for SnowSQL
if ! command -v snowsql &> /dev/null; then
    echo "Error: SnowSQL not found. Please install it first."
    exit 1
fi

# Deploy in sequence
SCRIPTS=(
    "01_setup_infrastructure.sql"
    "02_create_raw_tables.sql"
    "03_create_int_tables.sql"
    "04_create_procedures.sql"
    "05_create_tasks.sql"
    "06_create_views.sql"
    "07_create_data_generator.sql"
)

for script in "${SCRIPTS[@]}"; do
    echo ">>> Deploying: $script"
    snowsql -D DB_PREFIX=$DB_PREFIX -f "deploy/$script" -o exit_on_error=true
done

# Run tests
echo ">>> Running tests..."
snowsql -D DB_PREFIX=$DB_PREFIX -f "tests/run_tests.sql" -o exit_on_error=true

# Enable tasks only for non-PROD
if [[ "$ENV" != "PROD" ]]; then
    echo ">>> Enabling tasks and loading demo data..."
    snowsql -D DB_PREFIX=$DB_PREFIX -f "deploy/08_enable_tasks.sql" -o exit_on_error=true
else
    echo ">>> PROD: Tasks remain suspended. Enable manually after validation."
fi

echo "=========================================="
echo "✅ Deployment to $ENV complete!"
echo "=========================================="
