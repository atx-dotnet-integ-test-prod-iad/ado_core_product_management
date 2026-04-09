# Migration Report: Microsoft SQL Server to PostgreSQL

## Overview

This report documents the complete migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL.

**Migration Date:** 2026-04-09  
**Source Database:** Microsoft SQL Server 2019 (ProductManagement)  
**Target Database:** PostgreSQL 13 (postgres)  
**Application Framework:** .NET 9.0, ADO.NET  

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| **Total SQL Statements Processed** | 7 |
| **Successfully Converted by DMS MCP Tool** | 0 |
| **Requiring Manual Intervention (DMS Failure)** | 7 |
| **Validated as Equivalent (SQL Equivalency Tool)** | 0 |
| **Validated as Non-Equivalent** | 0 |
| **Equivalency Validation Errors** | 7 |

### DMS Tool Status
- **Tool:** dms-mcp___statement_conversion_tool
- **Migration Project ARN:** arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU
- **Error:** All 7 DMS conversion attempts failed with: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Fallback:** Manual conversion using DMS schema mapping with lowercase schema conventions (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)

### SQL Equivalency Tool Status
- **Tool:** sql-equivalency___validate_sql_equivalence
- **Error:** All 7 equivalency validations returned ERROR with: `'uniqueID'`
- **Note:** This appears to be a system-level issue with the equivalency tool, not related to statement quality

---

## Schema Mapping (from DMS Schema Mapping Tool)

The DMS schema mapping tool successfully retrieved schema mappings:

| Source (SQL Server) | Target (PostgreSQL) | Schema |
|---|---|---|
| dbo.Products | productmanagement_dbo.products | Lowercase columns |
| dbo.ProductHistory | productmanagement_dbo.producthistory | Lowercase columns |
| dbo.ProductStats | productmanagement_dbo.productstats | Lowercase columns |

### Key Schema Transformations
- All table names: PascalCase → lowercase (e.g., `Products` → `products`)
- All column names: PascalCase → lowercase (e.g., `ProductId` → `productid`, `StockQuantity` → `stockquantity`)
- `int IDENTITY(1,1)` → `INTEGER GENERATED ALWAYS AS IDENTITY`
- `datetime` → `TIMESTAMP WITHOUT TIME ZONE`
- `decimal(18,2)` → `NUMERIC(18,2)`
- `nvarchar` → `VARCHAR`
- `bit` → `NUMERIC(1,0)`
- `GETDATE()` → `clock_timestamp()`

---

## SQL Statement Details

### Statement 1: GetAllProductsAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** GetAllProductsAsync
- **Type:** SELECT with CTE, Window Functions (AVG, COUNT), CASE, ROUND, INNER JOIN
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:** Table/column names lowercased, CTE alias renamed to avoid conflict with table name

### Statement 2: GetProductByIdAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** GetProductByIdAsync
- **Type:** SELECT with CTE, LAG Window Function, LEFT JOIN, CASE, ROUND, Parameterized
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:** Table/column names lowercased, CTE alias renamed

### Statement 3: InsertProductAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** InsertProductAsync
- **Type:** Transaction block with INSERT, SCOPE_IDENTITY(), INSERT history, UPDATE stats
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:**
  - `SCOPE_IDENTITY()` → `RETURNING productid` clause
  - `GETDATE()` → `clock_timestamp()`
  - Transaction block restructured from single SQL batch to multiple C# managed commands
  - `DECLARE @var / SET @var` → C# variable handling

### Statement 4: UpdateProductAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** UpdateProductAsync
- **Type:** Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT history, UPDATE stats
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:**
  - `GETDATE()` → `clock_timestamp()`
  - `DECLARE @var / SELECT @var = column` → C# DataReader with separate query
  - Transaction block restructured to multiple C# managed commands

### Statement 5: DeleteProductAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** DeleteProductAsync
- **Type:** Transaction block with DECLARE, SELECT INTO, INSERT history, DELETE, UPDATE stats with CASE
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:**
  - `GETDATE()` → `clock_timestamp()`
  - `DECLARE @var / SELECT @var = column` → C# DataReader with separate query
  - Transaction block restructured to multiple C# managed commands

### Statement 6: GetProductsByPriceRangeAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** GetProductsByPriceRangeAsync
- **Type:** SELECT with CTE, RANK(), PERCENT_RANK() Window Functions, BETWEEN, CASE, Parameterized
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:** Table/column names lowercased

### Statement 7: GetLowStockProductsAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** GetLowStockProductsAsync
- **Type:** SELECT with CTE, AVG/MIN/MAX Window Functions, CASE, ROUND, Parameterized
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:** Table/column names lowercased, added CAST(stockquantity AS NUMERIC) for integer division fix

---

## File Changes Summary

### 1. DataAccess/ProductRepository.cs
- **SQL Statements:** All 7 SQL statements converted from MS SQL Server syntax to PostgreSQL syntax
- **ADO.NET Classes:** All SQL Server ADO.NET classes replaced with Npgsql equivalents:
  - `using Microsoft.Data.SqlClient` → `using Npgsql`
  - `SqlConnection` → `NpgsqlConnection` (3 occurrences)
  - `SqlCommand` → `NpgsqlCommand` (15 occurrences)
  - `SqlDataReader` → `NpgsqlDataReader` (1 occurrence)
  - `SqlTransaction` → `NpgsqlTransaction` (3 occurrences)
- **Transaction Handling:** InsertProductAsync, UpdateProductAsync, DeleteProductAsync restructured from SQL-embedded transactions to C# managed transactions
- **Column References:** MapProductFromReader updated to use lowercase column names

### 2. AdoCore.csproj
- **Package Reference:** `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.9`
- **Note:** Used 8.0.9 instead of 8.0.1 to address known high severity vulnerability (GHSA-x9vc-6hfv-hg8c)

### 3. appsettings.json
- **Connection Strings:** Updated from SQL Server format to PostgreSQL format:
  - `Server=localhost` → `Host=localhost`
  - `Database=ProductManagement` → `Database=postgres`
  - Removed: `Trusted_Connection=True`, `MultipleActiveResultSets=true`, `TrustServerCertificate=True`
  - Added: `Port=5432`, `Username=postgres`, `Password=postgres`

---

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| extracted_statements.sql | sourceCode/ | Complete catalog of all 7 original MS SQL Server statements |
| converted_statements.sql | sourceCode/ | Complete catalog of all 7 converted PostgreSQL statements |
| sql_equivalency_validation_report.json | sourceCode/ | Comprehensive equivalency validation report with all 7 statement pairs |
| migration_report.md | sourceCode/ | This report |

---

## Statements Requiring Manual Review

**All 7 statements require manual review** due to:
1. DMS tool failure prevented automated conversion verification
2. SQL Equivalency tool returned ERROR for all statement pairs (tool system issue)
3. Manual conversions followed DMS schema mapping conventions but should be verified against target PostgreSQL database

### Priority Review Items
- **Statement 3 (InsertProductAsync):** Major restructuring - SCOPE_IDENTITY() replaced with RETURNING clause, transaction block split into multiple commands
- **Statement 4 (UpdateProductAsync):** Transaction block split, DECLARE/SELECT INTO replaced with C# DataReader
- **Statement 5 (DeleteProductAsync):** Transaction block split, DECLARE/SELECT INTO replaced with C# DataReader
- **Statement 7 (GetLowStockProductsAsync):** Added explicit CAST for integer division (StockQuantity / AvgStock)

---

## Build Status

**Final Build:** ✅ SUCCESS (0 errors)
- Build command: `dotnet build`
- Result: All projects compiled successfully with no errors
- Warnings: Pre-existing nullable reference type warnings only (CS8601, CS8603, CS8618, CS8625, CS8600)
