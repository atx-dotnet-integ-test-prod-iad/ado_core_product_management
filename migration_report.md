# Migration Report: MS SQL Server to PostgreSQL - AdoCore Application

## Overview
This report documents the migration of the AdoCore .NET ADO application from Microsoft SQL Server to PostgreSQL.

**Migration Date:** 2026-04-23  
**Source Database:** Microsoft SQL Server 2019  
**Target Database:** PostgreSQL 13  
**Application Framework:** .NET 9.0 with ADO.NET  

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Statements Successfully Converted by DMS | 0 |
| Statements Requiring Manual Intervention | 7 |
| Statements Validated as Equivalent | 0 |
| Statements Validated as Non-Equivalent | 0 |
| Statements with Equivalency Validation Errors | 7 |

### DMS Tool Status
All 7 SQL statements were submitted to the AWS DMS MCP tool (dms-mcp___statement_conversion_tool) for conversion. All 7 failed with the same error:
- **Error:** `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Migration Project:** `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`

As per the transformation definition, manual conversion was applied with lowercase schema object names for PostgreSQL compatibility (`DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`).

### SQL Equivalency Tool Status
All 7 statement pairs were submitted to the SQL Equivalency MCP tool (sql-equivalency___validate_sql_equivalence) for validation. All 7 returned ERROR status:
- **Error:** `'uniqueID'` (tool infrastructure issue)
- All equivalency statuses are marked as ERROR based solely on tool output (no agent judgment applied)

## Statement-by-Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Method:** GetAllProductsAsync()
- **Type:** SELECT with CTE, Window Functions (AVG OVER, COUNT OVER), INNER JOIN, CASE, ROUND
- **Key Changes:** Schema objects lowercased, ROUND wrapped with CAST(... AS numeric)
- **DMS Status:** Failed
- **Equivalency Status:** ERROR

### Statement 2: GetProductByIdAsync
- **Method:** GetProductByIdAsync(int)
- **Type:** SELECT with CTE, LAG Window Function, LEFT JOIN, CASE, ROUND, Parameterized WHERE
- **Key Changes:** Schema objects lowercased, ROUND wrapped with CAST(... AS numeric)
- **DMS Status:** Failed
- **Equivalency Status:** ERROR

### Statement 3: InsertProductAsync
- **Method:** InsertProductAsync(Product)
- **Type:** Transaction block with INSERT, SCOPE_IDENTITY(), INSERT history, UPDATE stats
- **Key Changes:** SCOPE_IDENTITY() → lastval(), GETDATE() → NOW(), BEGIN TRANSACTION → BEGIN, DECLARE removed
- **DMS Status:** Failed
- **Equivalency Status:** ERROR

### Statement 4: UpdateProductAsync
- **Method:** UpdateProductAsync(Product)
- **Type:** Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT history, UPDATE stats
- **Key Changes:** Converted to DO $$ block with local variables, GETDATE() → NOW(), Schema objects lowercased
- **DMS Status:** Failed
- **Equivalency Status:** ERROR

### Statement 5: DeleteProductAsync
- **Method:** DeleteProductAsync(int)
- **Type:** Transaction block with DECLARE, SELECT INTO variables, INSERT history, DELETE, UPDATE stats with CASE
- **Key Changes:** Converted to DO $$ block with local variables, GETDATE() → NOW(), Schema objects lowercased
- **DMS Status:** Failed
- **Equivalency Status:** ERROR

### Statement 6: GetProductsByPriceRangeAsync
- **Method:** GetProductsByPriceRangeAsync(decimal, decimal)
- **Type:** SELECT with CTE, RANK(), PERCENT_RANK() Window Functions, BETWEEN, CASE
- **Key Changes:** Schema objects lowercased
- **DMS Status:** Failed
- **Equivalency Status:** ERROR

### Statement 7: GetLowStockProductsAsync
- **Method:** GetLowStockProductsAsync(int)
- **Type:** SELECT with CTE, AVG/MIN/MAX OVER() Window Functions, CASE, ROUND
- **Key Changes:** Schema objects lowercased, ROUND wrapped with CAST(... AS numeric)
- **DMS Status:** Failed
- **Equivalency Status:** ERROR

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | All 7 SQL statements converted to PostgreSQL; `using Microsoft.Data.SqlClient` → `using Npgsql`; `SqlConnection` → `NpgsqlConnection`; `SqlCommand` → `NpgsqlCommand`; `SqlDataReader` → `NpgsqlDataReader` |
| `AdoCore.csproj` | `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.6` |
| `appsettings.json` | Connection strings converted from SQL Server format to PostgreSQL format |

## New Artifacts Created

| File | Description |
|------|-------------|
| `extracted_statements.sql` | Complete catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Complete catalog of all 7 converted PostgreSQL statements |
| `dms_failure_log.md` | Detailed DMS failure documentation for all 7 statements |
| `sql_equivalency_validation_report.json` | Comprehensive JSON report with all statement pairs, conversion methods, and equivalency results |
| `migration_report.md` | This migration report |

## Package Changes

| Original Package | Version | New Package | Version |
|-----------------|---------|-------------|---------|
| Microsoft.Data.SqlClient | 5.1.4 | Npgsql | 8.0.6 |

Note: Npgsql 8.0.6 was selected over 8.0.0 to avoid known vulnerability GHSA-x9vc-6hfv-hg8c.

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server | `Server=localhost` | `Host=localhost` |
| Port | (default 1433) | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | Removed (not applicable) |
| TrustServerCertificate | `TrustServerCertificate=True` | Removed (not applicable) |

## ADO.NET Class Replacements

| SQL Server Class | Npgsql Class | Occurrences |
|-----------------|--------------|-------------|
| SqlConnection | NpgsqlConnection | 3 (field, method return, constructor) |
| SqlCommand | NpgsqlCommand | 7 (one per SQL method) |
| SqlDataReader | NpgsqlDataReader | 1 (MapProductFromReader parameter) |

## Build Status
- **Final Build:** ✅ SUCCESS (0 errors, 10 warnings - all pre-existing nullable reference warnings)

## Issues and Warnings

1. **DMS Tool Unavailable:** All 7 DMS conversion attempts failed with metadata model creation error. Manual conversion with lowercase schema was applied as fallback.
2. **SQL Equivalency Tool Error:** All 7 equivalency validation attempts returned ERROR with "'uniqueID'" error. This appears to be a tool infrastructure issue.
3. **Security:** Npgsql was upgraded from 8.0.0 to 8.0.6 to address known vulnerability GHSA-x9vc-6hfv-hg8c.
4. **Pre-existing Warnings:** 10 nullable reference warnings exist in the codebase (pre-existing, not introduced by migration).

## Recommendations for Manual Review
1. All 7 SQL statements should be manually reviewed for PostgreSQL compatibility since both DMS and equivalency tools were unavailable.
2. The DO $$ blocks used for Statements 4 and 5 (Update/Delete) should be tested against a real PostgreSQL database to verify parameter binding works correctly with Npgsql.
3. The `lastval()` usage in Statement 3 (Insert) should be verified in the context of concurrent connections.
4. Connection string credentials should be updated from placeholder values before deployment.
