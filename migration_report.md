# Migration Report: MS SQL Server to PostgreSQL

## Overview

**Project:** AdoCore - Product Management Application  
**Source Database:** Microsoft SQL Server 2019  
**Target Database:** PostgreSQL 13  
**Framework:** .NET 9.0 with ADO.NET  
**Migration Date:** 2026-03-25  

## Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements successfully converted by DMS | 0 |
| Statements requiring manual intervention | 7 |
| Statements validated as equivalent | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency errors | 7 |

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements converted to PostgreSQL, ADO.NET classes replaced (SqlClient → Npgsql) |
| `AdoCore.csproj` | Package reference: Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| `appsettings.json` | Connection strings updated from SQL Server format to PostgreSQL format |

## Package Changes

| Original | Replacement |
|----------|-------------|
| Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.6 |

## Class Replacements

| SQL Server Class | Npgsql Equivalent |
|-----------------|-------------------|
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `using Microsoft.Data.SqlClient` | `using Npgsql` |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Port | (default 1433) | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | Removed (not applicable) |
| TLS | `TrustServerCertificate=True` | Removed |

## SQL Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Type:** CTE with AVG/COUNT window functions, CASE, ROUND
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** Table/column names lowercased, CTE renamed (ProductStats → productstats_cte to avoid table name conflict)
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)

### Statement 2: GetProductByIdAsync
- **Type:** CTE with LAG window function, parameterized WHERE
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** Table/column names lowercased, CTE renamed (ProductHistory → producthistory_cte)
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)

### Statement 3: InsertProductAsync
- **Type:** Transaction with INSERT, SCOPE_IDENTITY(), GETDATE(), multi-table operations
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** 
  - SCOPE_IDENTITY() → RETURNING productid
  - GETDATE() → clock_timestamp()
  - Single T-SQL batch → Multiple C# commands in NpgsqlTransaction
  - DECLARE @NewProductId → C# variable (newProductId)
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)

### Statement 4: UpdateProductAsync
- **Type:** Transaction with DECLARE variables, UPDATE, INSERT history
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:**
  - DECLARE @OldPrice/@OldStock → SELECT INTO C# variables
  - GETDATE() → clock_timestamp()
  - Single T-SQL batch → Multiple C# commands in NpgsqlTransaction
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)

### Statement 5: DeleteProductAsync
- **Type:** Transaction with DECLARE, DELETE, CASE in UPDATE stats
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:**
  - DECLARE @OldPrice/@OldStock → SELECT INTO C# variables
  - GETDATE() → clock_timestamp()
  - Single T-SQL batch → Multiple C# commands in NpgsqlTransaction
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)

### Statement 6: GetProductsByPriceRangeAsync
- **Type:** CTE with RANK/PERCENT_RANK, BETWEEN, CASE
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** Table/column names lowercased
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)

### Statement 7: GetLowStockProductsAsync
- **Type:** CTE with AVG/MIN/MAX OVER(), ROUND, CASE
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** Table/column names lowercased, added ::NUMERIC cast for integer division in ROUND
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)

## DMS Tool Status

The DMS MCP statement conversion tool (dms-mcp___statement_conversion_tool) consistently failed with metadata model creation/conversion timeout errors across all attempts. The DMS schema mapping tool (dms-mcp___schema_mapping_tool) was successfully used to obtain authoritative schema name mappings for all 3 tables (Products, ProductHistory, ProductStats), which guided the manual lowercase conversion.

**DMS Errors:**
- Metadata model conversion did not complete after 15 attempts
- Metadata model creation did not complete after 20 attempts  
- Command execution timed out after 300 seconds

## SQL Equivalency Tool Status

The SQL Equivalency tool (sql-equivalency___validate_sql_equivalence) returned ERROR with `'uniqueID'` for all 7 statement pairs. This appears to be a systemic tool issue rather than a statement-specific problem. All equivalency statuses are reported as ERROR per tool output - no agent judgment was applied.

## Schema Mapping Reference (from DMS schema_mapping_tool)

| Source (SQL Server) | Target (PostgreSQL) |
|--------------------|--------------------|
| dbo.Products | productmanagement_dbo.products |
| dbo.ProductHistory | productmanagement_dbo.producthistory |
| dbo.ProductStats | productmanagement_dbo.productstats |
| ProductId | productid |
| Name | name |
| Description | description |
| Price | price |
| StockQuantity | stockquantity |
| CreatedDate | createddate |
| ModifiedDate | modifieddate |
| GETDATE() | clock_timestamp() |
| IDENTITY | GENERATED ALWAYS AS IDENTITY |

## Statements Requiring Manual Review

All 7 statements require manual review due to:
1. DMS conversion failure (all used manual conversion with lowercase schema)
2. SQL Equivalency tool unable to validate (returned ERROR for all)

**Recommendation:** Manual testing against the PostgreSQL database is recommended to verify functional equivalency of all 7 converted statements.

## Build Status

✅ Application compiles successfully with `dotnet build` (0 errors, 10 warnings - all pre-existing nullable reference warnings)

## Migration Artifacts

| Artifact | Status |
|----------|--------|
| `extracted_statements.sql` | ✅ Complete (7 statements) |
| `converted_statements.sql` | ✅ Complete (7 statements) |
| `sql_equivalency_validation_report.json` | ✅ Complete (7 statement pairs) |
| `dms_failures_log.txt` | ✅ Complete (all DMS failures documented) |
| `migration_report.md` | ✅ This file |

## Final Verification Checklist

- [x] All SQL Server packages replaced with PostgreSQL equivalents
- [x] All SqlClient ADO.NET classes replaced with Npgsql
- [x] All SQL statements processed through DMS MCP tool (attempted, all failed)
- [x] All statement pairs validated through SQL Equivalency tool (all returned ERROR)
- [x] Connection strings updated to PostgreSQL format
- [x] Comprehensive artifacts generated
- [x] Application compiles successfully
