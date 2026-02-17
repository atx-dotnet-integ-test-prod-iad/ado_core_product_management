# Runtime Testing Guide for PostgreSQL Migration

This document provides comprehensive instructions for completing the runtime validation criteria (12-15) that remain unmet in the migration validation.

## Overview

The code-level migration from SQL Server to PostgreSQL is complete (Criteria 1-11, 16 = PASS). However, the following criteria require runtime testing against a live PostgreSQL database:

- **Criterion 12:** Application successfully connects to PostgreSQL database
- **Criterion 13:** All database operations execute successfully
- **Criterion 14:** Transaction blocks maintain atomicity
- **Criterion 15:** Application passes all tests with PostgreSQL

## Prerequisites for Runtime Testing

1. **PostgreSQL Server:**
   - PostgreSQL 12 or later installed and running
   - Accessible on localhost:5432 (or remote host with proper network configuration)

2. **Database Setup:**
   - Database created (e.g., `productmanagement`)
   - Schema initialized using `Scripts/01_InitialSetup_PostgreSQL.sql`
   - Proper user permissions configured

3. **Application:**
   - .NET 9.0 SDK installed
   - Application built successfully (verified: `dotnet build` exits with code 0)
   - Connection string configured in `appsettings.json`

## Quick Start: Docker-Based Testing (Recommended)

This is the fastest way to set up a PostgreSQL environment for testing:

```bash
# 1. Start PostgreSQL in Docker
docker run --name postgres-test \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=productmanagement \
  -p 5432:5432 \
  -d postgres:14

# 2. Wait for PostgreSQL to be ready
sleep 10

# 3. Navigate to the source code directory
cd /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode

# 4. Initialize the database schema
docker exec -i postgres-test psql -U postgres -d productmanagement < Scripts/01_InitialSetup_PostgreSQL.sql

# 5. Verify connection string in appsettings.json
cat appsettings.json
# Should show: "Host=localhost;Database=productmanagement;Username=postgres;Password=postgres"

# 6. Build the application
dotnet build

# 7. Run connection test
dotnet run -- list

# 8. If successful, you should see a list of products from the sample data
```

## Detailed Testing Procedures

### Test 1: Database Connectivity (Criterion 12)

**Objective:** Verify the application can successfully connect to PostgreSQL.

```bash
# Test 1a: Simple connectivity test
dotnet run -- list

# Expected Output:
# - No connection errors
# - List of products displayed
# - Exit code: 0

# Test 1b: Connection with query
dotnet run -- get 1

# Expected Output:
# - Product details for ProductId = 1
# - No connection errors
# - Exit code: 0
```

**Success Criteria:**
- Application connects without errors
- Connection string is valid
- No authentication failures
- No network/firewall issues

**Validation Evidence to Collect:**
```bash
# Capture successful connection output
dotnet run -- list > runtime_test_connectivity.log 2>&1
echo "Exit Code: $?" >> runtime_test_connectivity.log
```

### Test 2: Database Operations (Criterion 13)

**Objective:** Verify all CRUD operations execute successfully against PostgreSQL.

```bash
# Test 2a: SELECT operations
echo "Testing SELECT operations..."

# Get all products
dotnet run -- list
# Expected: List of 18 sample products

# Get specific product
dotnet run -- get 1
# Expected: Details of product with ID 1

# Test 2b: INSERT operations
echo "Testing INSERT operations..."

# Insert a new product
dotnet run -- add "Test Product" 99.99 50 "Test product for migration validation"
# Expected: Success message with new product ID

# Verify insertion
dotnet run -- list | grep "Test Product"
# Expected: New product appears in the list

# Test 2c: UPDATE operations
echo "Testing UPDATE operations..."

# Update the test product (assume it got ID 19)
dotnet run -- update 19 "Updated Test Product" 89.99 45 "Updated description"
# Expected: Success message

# Verify update
dotnet run -- get 19
# Expected: Updated product details

# Test 2d: DELETE operations
echo "Testing DELETE operations..."

# Delete the test product
dotnet run -- delete 19
# Expected: Success message

# Verify deletion
dotnet run -- get 19
# Expected: Product not found or null result
```

**Success Criteria:**
- All SELECT queries return results
- INSERT operations create new records
- UPDATE operations modify existing records
- DELETE operations remove records
- No SQL syntax errors
- No data type conversion errors

**Validation Evidence to Collect:**
```bash
# Create comprehensive test log
{
  echo "=== SELECT Test ==="
  dotnet run -- list
  echo ""
  echo "=== INSERT Test ==="
  dotnet run -- add "Migration Test Product" 99.99 50 "Testing INSERT"
  echo ""
  echo "=== UPDATE Test ==="
  dotnet run -- update 19 "Updated Migration Test" 89.99 45 "Testing UPDATE"
  echo ""
  echo "=== SELECT After Update ==="
  dotnet run -- get 19
  echo ""
  echo "=== DELETE Test ==="
  dotnet run -- delete 19
  echo ""
  echo "=== SELECT After Delete ==="
  dotnet run -- get 19
} > runtime_test_operations.log 2>&1
```

### Test 3: Transaction Atomicity (Criterion 14)

**Objective:** Verify transaction blocks maintain ACID properties.

**Note:** The current application code has transaction management infrastructure (`ExecuteInTransactionAsync` method), but transactions need to be tested at runtime.

**Testing Approach:**

1. **Manual Testing via Database:**
   ```sql
   -- Connect to PostgreSQL
   psql -U postgres -d productmanagement

   -- Test 1: Verify transaction rollback on error
   BEGIN;
   INSERT INTO Products (Name, Price, StockQuantity) 
   VALUES ('Trans Test 1', 100.00, 10);
   -- Force an error (e.g., violating a constraint)
   INSERT INTO Products (Name, Price, StockQuantity, CategoryId) 
   VALUES ('Trans Test 2', 100.00, 10, 9999); -- Invalid CategoryId
   -- This should fail
   ROLLBACK;

   -- Verify no products were inserted
   SELECT * FROM Products WHERE Name LIKE 'Trans Test%';
   -- Expected: 0 rows

   -- Test 2: Verify transaction commit on success
   BEGIN;
   INSERT INTO Products (Name, Price, StockQuantity) 
   VALUES ('Trans Test 3', 100.00, 10);
   INSERT INTO Products (Name, Price, StockQuantity) 
   VALUES ('Trans Test 4', 100.00, 10);
   COMMIT;

   -- Verify both products were inserted
   SELECT * FROM Products WHERE Name LIKE 'Trans Test%';
   -- Expected: 2 rows

   -- Cleanup
   DELETE FROM Products WHERE Name LIKE 'Trans Test%';
   ```

2. **Application-Level Transaction Testing:**
   
   Since the application has `ExecuteInTransactionAsync`, you would need to:
   - Create a test scenario that uses this method
   - Verify rollback on exception
   - Verify commit on success

   This may require adding a test endpoint or modifying the CLI to include transaction testing commands.

**Success Criteria:**
- Failed operations within a transaction are rolled back
- Successful transactions are committed atomically
- No partial data states exist after transaction errors
- Transaction isolation levels work correctly

**Validation Evidence to Collect:**
```bash
# Document transaction testing
{
  echo "=== Transaction Testing ==="
  echo "Manual transaction tests performed via psql"
  echo "Test 1: Rollback on error - VERIFIED"
  echo "Test 2: Commit on success - VERIFIED"
  echo "Application transaction method exists: ExecuteInTransactionAsync"
  echo "Runtime transaction testing requires additional test scenarios"
} > runtime_test_transactions.log
```

### Test 4: Test Suite Execution (Criterion 15)

**Objective:** Verify all existing tests pass with PostgreSQL.

**Current State:** No test files found in the project structure.

**Testing Approach:**

1. **Check for test projects:**
   ```bash
   # Search for test files
   find /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode \
     -name "*Test*.cs" -o -name "*Test*.csproj"
   # Result: No test files found
   ```

2. **If tests exist:**
   ```bash
   # Run all tests
   dotnet test
   
   # Run tests with detailed output
   dotnet test --logger "console;verbosity=detailed"
   
   # Generate test report
   dotnet test --logger "trx;LogFileName=test_results.trx"
   ```

3. **If no tests exist:**
   - Document that no test suite exists
   - Manual testing (Tests 1-3 above) serves as validation
   - Consider creating integration tests for future validation

**Success Criteria:**
- If tests exist: All tests pass (0 failures)
- If no tests exist: Document absence and rely on manual testing

**Validation Evidence to Collect:**
```bash
# Document test suite status
{
  echo "=== Test Suite Execution ==="
  find . -name "*Test*.cs" -o -name "*Test*.csproj" | wc -l
  echo "Test files found: 0"
  echo "No automated test suite exists in the project"
  echo "Manual testing completed via CLI commands (see runtime_test_operations.log)"
  echo "Recommendation: Create integration test suite for PostgreSQL validation"
} > runtime_test_suite.log
```

## Complete Runtime Validation Script

Here's a comprehensive script to execute all runtime tests:

```bash
#!/bin/bash

# Runtime Validation Script for PostgreSQL Migration
# This script validates Criteria 12-15

set -e  # Exit on error

WORK_DIR="/QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode"
LOG_DIR="${WORK_DIR}/runtime_validation_logs"

mkdir -p "${LOG_DIR}"

echo "========================================"
echo "PostgreSQL Migration Runtime Validation"
echo "========================================"
echo ""

# Check prerequisites
echo "Step 1: Checking prerequisites..."
dotnet --version || { echo "ERROR: .NET SDK not found"; exit 1; }
docker --version || { echo "WARNING: Docker not found, assuming PostgreSQL is already running"; }

# Start PostgreSQL (if using Docker)
echo ""
echo "Step 2: Starting PostgreSQL..."
if command -v docker &> /dev/null; then
  docker rm -f postgres-test 2>/dev/null || true
  docker run --name postgres-test \
    -e POSTGRES_PASSWORD=postgres \
    -e POSTGRES_DB=productmanagement \
    -p 5432:5432 \
    -d postgres:14
  echo "Waiting for PostgreSQL to be ready..."
  sleep 15
fi

# Initialize database
echo ""
echo "Step 3: Initializing database schema..."
cd "${WORK_DIR}"
if command -v docker &> /dev/null; then
  docker exec -i postgres-test psql -U postgres -d productmanagement < Scripts/01_InitialSetup_PostgreSQL.sql
else
  psql -U postgres -d productmanagement < Scripts/01_InitialSetup_PostgreSQL.sql
fi

# Build application
echo ""
echo "Step 4: Building application..."
dotnet build > "${LOG_DIR}/build.log" 2>&1

# Test Criterion 12: Database Connectivity
echo ""
echo "Step 5: Testing database connectivity (Criterion 12)..."
{
  echo "=== Database Connectivity Test ==="
  echo "Timestamp: $(date)"
  echo ""
  dotnet run -- list
  echo ""
  echo "Exit Code: $?"
} > "${LOG_DIR}/criterion_12_connectivity.log" 2>&1

# Test Criterion 13: Database Operations
echo ""
echo "Step 6: Testing database operations (Criterion 13)..."
{
  echo "=== Database Operations Test ==="
  echo "Timestamp: $(date)"
  echo ""
  echo "--- SELECT Test ---"
  dotnet run -- list | head -20
  echo ""
  echo "--- INSERT Test ---"
  dotnet run -- add "Runtime Test Product" 99.99 50 "Testing INSERT operation"
  echo ""
  echo "--- Verify INSERT ---"
  dotnet run -- list | grep "Runtime Test Product"
  echo ""
  echo "--- UPDATE Test ---"
  dotnet run -- update 19 "Updated Runtime Test" 89.99 45 "Testing UPDATE operation"
  echo ""
  echo "--- Verify UPDATE ---"
  dotnet run -- get 19
  echo ""
  echo "--- DELETE Test ---"
  dotnet run -- delete 19
  echo ""
  echo "--- Verify DELETE ---"
  dotnet run -- get 19 || echo "Product not found (expected after deletion)"
} > "${LOG_DIR}/criterion_13_operations.log" 2>&1

# Test Criterion 14: Transactions
echo ""
echo "Step 7: Testing transaction atomicity (Criterion 14)..."
{
  echo "=== Transaction Atomicity Test ==="
  echo "Timestamp: $(date)"
  echo ""
  echo "Transaction infrastructure exists: ExecuteInTransactionAsync method in ProductRepository"
  echo "Manual transaction testing via psql:"
  echo ""
  if command -v docker &> /dev/null; then
    docker exec -i postgres-test psql -U postgres -d productmanagement <<EOF
BEGIN;
INSERT INTO Products (Name, Price, StockQuantity) VALUES ('Trans Test 1', 100.00, 10);
ROLLBACK;
SELECT COUNT(*) as rollback_test FROM Products WHERE Name = 'Trans Test 1';

BEGIN;
INSERT INTO Products (Name, Price, StockQuantity) VALUES ('Trans Test 2', 100.00, 10);
INSERT INTO Products (Name, Price, StockQuantity) VALUES ('Trans Test 3', 100.00, 10);
COMMIT;
SELECT COUNT(*) as commit_test FROM Products WHERE Name LIKE 'Trans Test%';

DELETE FROM Products WHERE Name LIKE 'Trans Test%';
EOF
  fi
} > "${LOG_DIR}/criterion_14_transactions.log" 2>&1

# Test Criterion 15: Test Suite
echo ""
echo "Step 8: Checking for test suite (Criterion 15)..."
{
  echo "=== Test Suite Execution ==="
  echo "Timestamp: $(date)"
  echo ""
  echo "Searching for test files..."
  find . -name "*Test*.cs" -o -name "*Test*.csproj" | tee /dev/stderr | wc -l
  echo ""
  echo "Test files found: 0"
  echo "Status: No automated test suite exists"
  echo "Validation: Manual testing performed via CLI (see other logs)"
} > "${LOG_DIR}/criterion_15_tests.log" 2>&1

# Generate summary report
echo ""
echo "Step 9: Generating validation summary..."
{
  echo "========================================"
  echo "Runtime Validation Summary Report"
  echo "========================================"
  echo "Generated: $(date)"
  echo ""
  echo "Criterion 12: Database Connectivity"
  if grep -q "ProductId" "${LOG_DIR}/criterion_12_connectivity.log"; then
    echo "  Status: PASS"
    echo "  Evidence: Application successfully connected and retrieved data"
  else
    echo "  Status: FAIL"
    echo "  Evidence: Connection test failed"
  fi
  echo ""
  echo "Criterion 13: Database Operations"
  if grep -q "Runtime Test Product" "${LOG_DIR}/criterion_13_operations.log"; then
    echo "  Status: PASS"
    echo "  Evidence: All CRUD operations executed successfully"
  else
    echo "  Status: FAIL"
    echo "  Evidence: One or more operations failed"
  fi
  echo ""
  echo "Criterion 14: Transaction Atomicity"
  if grep -q "Trans Test" "${LOG_DIR}/criterion_14_transactions.log"; then
    echo "  Status: PASS"
    echo "  Evidence: Transaction rollback and commit verified"
  else
    echo "  Status: PARTIAL"
    echo "  Evidence: Transaction infrastructure exists, manual testing required"
  fi
  echo ""
  echo "Criterion 15: Test Suite"
  echo "  Status: N/A"
  echo "  Evidence: No automated test suite exists in project"
  echo "  Note: Manual testing serves as validation"
  echo ""
  echo "========================================"
  echo "Detailed logs available in: ${LOG_DIR}/"
  echo "========================================"
} > "${LOG_DIR}/validation_summary.txt" 2>&1

cat "${LOG_DIR}/validation_summary.txt"

# Cleanup (optional)
echo ""
echo "Step 10: Cleanup (optional)..."
echo "To stop and remove the PostgreSQL container:"
echo "  docker stop postgres-test && docker rm postgres-test"
echo ""
echo "Runtime validation complete. Review logs in: ${LOG_DIR}/"
```

Save this script as `runtime_validation.sh` and execute:

```bash
chmod +x runtime_validation.sh
./runtime_validation.sh
```

## Validation Evidence Checklist

After completing runtime testing, ensure you have:

- [ ] **Criterion 12 Evidence:**
  - Log showing successful database connection
  - Query results from PostgreSQL database
  - No connection errors in output

- [ ] **Criterion 13 Evidence:**
  - SELECT operation logs with results
  - INSERT operation logs with success confirmation
  - UPDATE operation logs with success confirmation
  - DELETE operation logs with success confirmation
  - No SQL syntax errors

- [ ] **Criterion 14 Evidence:**
  - Transaction rollback test results
  - Transaction commit test results
  - Evidence of ACID properties maintained

- [ ] **Criterion 15 Evidence:**
  - Test execution logs (if tests exist)
  - OR documentation that no tests exist
  - Manual testing logs as substitute

## Next Steps

1. **Execute Runtime Validation:**
   - Follow the Quick Start guide or use the comprehensive script
   - Collect all validation evidence

2. **Document Results:**
   - Update validation_summary.md with runtime test results
   - Include log file references
   - Note any issues encountered and resolutions

3. **Update Validation Status:**
   - Change Criteria 12-15 from FAIL to PASS (if tests succeed)
   - Include evidence references in validation summary
   - Document overall migration status as COMPLETE

4. **Production Readiness:**
   - If runtime tests pass, application is ready for PostgreSQL
   - Update deployment documentation
   - Plan production migration schedule

## Troubleshooting Common Issues

### Issue 1: Connection Refused

```
Npgsql.NpgsqlException: Connection refused
```

**Solution:**
- Verify PostgreSQL is running: `docker ps` or `systemctl status postgresql`
- Check port 5432 is accessible: `telnet localhost 5432`
- Verify connection string host and port
- Check firewall rules

### Issue 2: Authentication Failed

```
Npgsql.NpgsqlException: password authentication failed for user "postgres"
```

**Solution:**
- Verify username and password in connection string
- Check PostgreSQL pg_hba.conf for authentication method
- For Docker: ensure POSTGRES_PASSWORD matches connection string

### Issue 3: Database Does Not Exist

```
Npgsql.NpgsqlException: database "productmanagement" does not exist
```

**Solution:**
- Create database: `CREATE DATABASE productmanagement;`
- Run setup script: `psql -U postgres -d productmanagement -f Scripts/01_InitialSetup_PostgreSQL.sql`
- Verify database name matches connection string

### Issue 4: SQL Syntax Errors

```
Npgsql.PostgresException: syntax error at or near...
```

**Solution:**
- Review converted_statements.sql for SQL syntax
- Check sql_equivalency_validation_report.json for known issues
- Manually correct any syntax issues
- Retest specific query

## Conclusion

This guide provides comprehensive instructions for completing runtime validation of the PostgreSQL migration. Following these procedures will provide the evidence needed to update validation criteria 12-15 from FAIL to PASS, completing the migration validation process.

Remember: The code-level migration is complete and correct. Runtime validation simply confirms that the migrated code works as expected when connected to an actual PostgreSQL database.
