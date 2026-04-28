# SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Value |
|--------|-------|
| **Migration Date** | 2026-04-28 |
| **Source Database** | Microsoft SQL Server 2019 |
| **Target Database** | PostgreSQL 13 |
| **Application Framework** | .NET 9.0 (ADO.NET) |
| **Total SQL Statements Processed** | 7 |
| **DMS Tool Conversion Status** | FAILED (all 7 statements) |
| **Manual Conversions Applied** | 7 |
| **Build Status** | SUCCESS |

---

## 1. SQL Statement Processing

### 1.1 DMS MCP Tool Results

The DMS MCP tool (`dms-mcp___statement_conversion_tool`) was used for all 7 statements but failed consistently:

- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Migration Project ARN**: `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`
- **Attempts**: 4 separate attempts with varied parameters
- **Result**: All attempts failed with the same metadata model creation error

### 1.2 Manual Conversion Summary

All 7 statements were manually converted using the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` approach:

| # | Method | Statement Type | Key Conversions |
|---|--------|---------------|-----------------|
| 1 | GetAllProductsAsync | SELECT with CTE, Window Functions | Lowercase schema objects |
| 2 | GetProductByIdAsync | SELECT with CTE, LAG | Lowercase schema objects |
| 3 | InsertProductAsync | Transaction Block | SCOPE_IDENTITY()→RETURNING, GETDATE()→NOW(), DECLARE→Multi-command |
| 4 | UpdateProductAsync | Transaction Block | DECLARE→Multi-command, GETDATE()→NOW() |
| 5 | DeleteProductAsync | Transaction Block | DECLARE→Multi-command, GETDATE()→NOW() |
| 6 | GetProductsByPriceRangeAsync | SELECT with CTE, RANK | Lowercase schema objects |
| 7 | GetLowStockProductsAsync | SELECT with CTE, AVG/MIN/MAX | Lowercase + CAST for integer division |

### 1.3 Key SQL Syntax Conversions

| MS SQL Server | PostgreSQL | Affected Statements |
|--------------|-----------|-------------------|
| `SCOPE_IDENTITY()` | `RETURNING productid` | 3 (InsertProductAsync) |
| `GETDATE()` | `NOW()` | 3, 4, 5 |
| `DECLARE @variable` | Multi-command with C# variables | 3, 4, 5 |
| `BEGIN TRANSACTION`/`COMMIT` | ADO.NET managed transaction | 3, 4, 5 |
| `ROUND(int / int * 100, 2)` | `ROUND(CAST(int AS NUMERIC) / int * 100, 2)` | 7 |
| PascalCase schema objects | lowercase schema objects | All 7 |

---

## 2. SQL Equivalency Validation

### 2.1 Equivalency Tool Results

The SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`) was used for all 7 statement pairs:

| Metric | Count |
|--------|-------|
| **Statements Processed** | 7 |
| **Equivalent** | 0 |
| **Non-Equivalent** | 0 |
| **Error** | 7 |

All 7 statements returned ERROR with: `{'equivalence_status': 'ERROR', 'error': "'uniqueID'"}`

The tool consistently returned this error for all queries, including a simple test query, indicating a systemic tool issue rather than a statement-specific problem.

### 2.2 Equivalency Report Location
- **File**: `sql_equivalency_validation_report.json`
- **Contents**: All 7 statement pairs with full details including original statements, converted statements, conversion method, equivalency status, and tool output

---

## 3. Code Changes

### 3.1 Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements, ADO.NET classes, column name references |
| `AdoCore.csproj` | Package reference replacement |
| `appsettings.json` | Connection string format |

### 3.2 ADO.NET Class Replacements

| Original (SQL Server) | Replacement (PostgreSQL) |
|-----------------------|------------------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

### 3.3 Package Reference Changes

| Original | Replacement |
|----------|-------------|
| `Microsoft.Data.SqlClient` v5.1.4 | `Npgsql` v9.0.3 |

**Note**: Npgsql v8.0.1 (initially planned) had a known high severity vulnerability (GHSA-x9vc-6hfv-hg8c). Upgraded to v9.0.3 which has no known vulnerabilities.

### 3.4 Connection String Changes

**Before (SQL Server)**:
```
Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True
```

**After (PostgreSQL)**:
```
Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres
```

| SQL Server Parameter | PostgreSQL Equivalent |
|---------------------|---------------------|
| `Server=` | `Host=` |
| `Database=` | `Database=` (unchanged) |
| `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| `MultipleActiveResultSets=true` | Removed (not applicable) |
| `TrustServerCertificate=True` | Removed (not applicable) |
| N/A | `Port=5432` (added) |

---

## 4. Method Restructuring Details

### 4.1 InsertProductAsync
- **Original**: Single SQL batch with `DECLARE`, `SCOPE_IDENTITY()`, `BEGIN TRANSACTION`/`COMMIT`
- **Converted**: 3 separate `NpgsqlCommand` calls within ADO.NET-managed transaction:
  1. `INSERT...RETURNING productid` (ExecuteScalar to get new ID)
  2. `INSERT INTO producthistory` (with returned ID as parameter)
  3. `UPDATE productstats`

### 4.2 UpdateProductAsync
- **Original**: Single SQL batch with `DECLARE`, `SELECT @var = col`, `BEGIN TRANSACTION`/`COMMIT`
- **Converted**: 4 separate `NpgsqlCommand` calls within ADO.NET-managed transaction:
  1. `SELECT price, stockquantity` (get old values into C# variables)
  2. `UPDATE products` (with new values)
  3. `INSERT INTO producthistory` (with old and new values)
  4. `UPDATE productstats` (with old and new prices)

### 4.3 DeleteProductAsync
- **Original**: Single SQL batch with `DECLARE`, `SELECT @var = col`, `BEGIN TRANSACTION`/`COMMIT`
- **Converted**: 4 separate `NpgsqlCommand` calls within ADO.NET-managed transaction:
  1. `SELECT price, stockquantity` (get old values)
  2. `INSERT INTO producthistory` (log deletion)
  3. `DELETE FROM products`
  4. `UPDATE productstats` (with CASE WHEN for division-by-zero protection)

---

## 5. Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | Project root | All 7 original MS SQL statements |
| `converted_statements.sql` | Project root | All 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Project root | Equivalency validation results for all 7 pairs |
| `dms_failure_log.txt` | Project root | DMS tool failure documentation |
| `migration_report.md` | Project root | This report |

---

## 6. Build Verification

- **Final Build**: SUCCESS (0 errors, 0 vulnerability warnings)
- **Warnings**: Standard nullable reference warnings (pre-existing, not introduced by migration)
- **No SQL Server References**: Verified no remaining references to `Microsoft.Data.SqlClient`, `SqlConnection`, `SqlCommand`, `SqlDataReader`, or `SqlParameter` in source code

---

## 7. Known Issues and Recommendations

1. **DMS Tool Unavailability**: The DMS MCP tool was unable to process any statements due to metadata model creation errors. All conversions were performed manually. It is recommended to re-validate the conversions when the DMS tool becomes available.

2. **SQL Equivalency Tool Error**: The SQL Equivalency tool returned errors for all 7 statement pairs. It is recommended to re-run equivalency validation when the tool is operational.

3. **Connection String Credentials**: The PostgreSQL connection strings use placeholder credentials (`postgres`/`postgres`). These should be updated to use proper credentials or environment variable-based configuration for production deployment.

4. **Transaction Restructuring**: Statements 3, 4, and 5 were restructured from single SQL batches to multiple ADO.NET commands. While functionally equivalent, this changes the execution pattern and should be tested thoroughly with the actual PostgreSQL database.
