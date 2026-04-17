# Migration Report: MS SQL Server to PostgreSQL

## Overview
| Metric | Value |
|--------|-------|
| **Migration Date** | 2026-04-17 |
| **Source Database** | MS SQL Server 2019 |
| **Target Database** | PostgreSQL 13 |
| **Application** | AdoCore (.NET 9 ADO.NET) |
| **Source Package** | Microsoft.Data.SqlClient 5.1.4 |
| **Target Package** | Npgsql 8.0.6 |

## SQL Statement Processing Summary

| Metric | Count |
|--------|-------|
| **Total SQL Statements Processed** | 7 |
| **Successfully Converted by DMS Tool** | 0 |
| **Requiring Manual Intervention (DMS Failed)** | 7 |
| **Validated as Equivalent (SQL Equivalency Tool)** | 0 |
| **Validated as Non-Equivalent** | 0 |
| **Equivalency Validation Errors** | 7 |

### DMS Tool Status
- **Status**: All 7 statements FAILED
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Schema Mapping Tool**: SUCCESSFUL - provided target schema mappings used for manual conversion
- **Manual Conversion Applied**: All 7 statements converted with `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

### SQL Equivalency Tool Status
- **Status**: All 7 validations returned ERROR
- **Error**: `'uniqueID'` (internal tool error)
- **Note**: Each statement pair was independently validated through the tool as required

## Schema Mapping (from DMS Schema Mapping Tool)

| Source (MS SQL) | Target (PostgreSQL) |
|-----------------|---------------------|
| `dbo.Products` | `productmanagement_dbo.products` |
| `dbo.ProductHistory` | `productmanagement_dbo.producthistory` |
| `dbo.ProductStats` | `productmanagement_dbo.productstats` |

### Column Mapping (all lowercase in target)
- `ProductId` → `productid`
- `Name` → `name`
- `Description` → `description`
- `Price` → `price`
- `StockQuantity` → `stockquantity`
- `CreatedDate` → `createddate`
- `ModifiedDate` → `modifieddate`
- `HistoryId` → `historyid`
- `Action` → `action`
- `OldPrice` → `oldprice`
- `NewPrice` → `newprice`
- `OldStock` → `oldstock`
- `NewStock` → `newstock`
- `ActionDate` → `actiondate`
- `StatId` → `statid`
- `TotalProducts` → `totalproducts`
- `AveragePrice` → `averageprice`
- `LastUpdated` → `lastupdated`

## Detailed Statement Migration

### Statement 1: GetAllProductsAsync
| Field | Value |
|-------|-------|
| **Source File** | DataAccess/ProductRepository.cs |
| **Method** | `GetAllProductsAsync()` |
| **Type** | SELECT with CTE, AVG/COUNT window functions, CASE, ROUND |
| **Conversion Method** | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR (tool returned `'uniqueID'`) |
| **Key Changes** | Table/column names lowercased; schema prefix `productmanagement_dbo` added; CTE alias renamed to avoid conflict with table name |

### Statement 2: GetProductByIdAsync
| Field | Value |
|-------|-------|
| **Source File** | DataAccess/ProductRepository.cs |
| **Method** | `GetProductByIdAsync(int productId)` |
| **Type** | SELECT with CTE, LAG window function, CASE, ROUND |
| **Conversion Method** | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR (tool returned `'uniqueID'`) |
| **Key Changes** | Table/column names lowercased; schema prefix added; CTE alias renamed |

### Statement 3: InsertProductAsync
| Field | Value |
|-------|-------|
| **Source File** | DataAccess/ProductRepository.cs |
| **Method** | `InsertProductAsync(Product product)` |
| **Type** | Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE() |
| **Conversion Method** | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR (tool returned `'uniqueID'`) |
| **Key Changes** | `SCOPE_IDENTITY()` → `RETURNING productid` with writable CTE; `GETDATE()` → `clock_timestamp()`; `BEGIN TRANSACTION/COMMIT` → single writable CTE statement; `DECLARE/SET` eliminated |

### Statement 4: UpdateProductAsync
| Field | Value |
|-------|-------|
| **Source File** | DataAccess/ProductRepository.cs |
| **Method** | `UpdateProductAsync(Product product)` |
| **Type** | Transaction block with DECLARE, SELECT into vars, UPDATE, INSERT, GETDATE() |
| **Conversion Method** | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR (tool returned `'uniqueID'`) |
| **Key Changes** | `DECLARE/SET` variables → CTE `old_values` subquery; `GETDATE()` → `clock_timestamp()`; `BEGIN TRANSACTION/COMMIT` → single writable CTE statement |

### Statement 5: DeleteProductAsync
| Field | Value |
|-------|-------|
| **Source File** | DataAccess/ProductRepository.cs |
| **Method** | `DeleteProductAsync(int productId)` |
| **Type** | Transaction block with DECLARE, SELECT into vars, INSERT, DELETE, UPDATE with CASE, GETDATE() |
| **Conversion Method** | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR (tool returned `'uniqueID'`) |
| **Key Changes** | `DECLARE/SET` variables → CTE `old_values` subquery; `GETDATE()` → `clock_timestamp()`; `BEGIN TRANSACTION/COMMIT` → single writable CTE statement; CASE expression preserved |

### Statement 6: GetProductsByPriceRangeAsync
| Field | Value |
|-------|-------|
| **Source File** | DataAccess/ProductRepository.cs |
| **Method** | `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)` |
| **Type** | SELECT with CTE, RANK/PERCENT_RANK window functions, BETWEEN, CASE |
| **Conversion Method** | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR (tool returned `'uniqueID'`) |
| **Key Changes** | Table/column names lowercased; schema prefix added |

### Statement 7: GetLowStockProductsAsync
| Field | Value |
|-------|-------|
| **Source File** | DataAccess/ProductRepository.cs |
| **Method** | `GetLowStockProductsAsync(int threshold)` |
| **Type** | SELECT with CTE, AVG/MIN/MAX window functions, CASE, ROUND |
| **Conversion Method** | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR (tool returned `'uniqueID'`) |
| **Key Changes** | Table/column names lowercased; schema prefix added; Added `CAST(stockquantity AS NUMERIC)` for proper decimal division in ROUND |

## Code Changes Summary

### Package Dependencies
| Change | Before | After |
|--------|--------|-------|
| NuGet Package | Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.6 |

### ADO.NET Class Replacements
| MS SQL Server | PostgreSQL (Npgsql) | Occurrences |
|---------------|---------------------|-------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |
| `SqlConnection` | `NpgsqlConnection` | 4 |
| `SqlCommand` | `NpgsqlCommand` | 7 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |

### Connection String Changes
| Parameter | Before (SQL Server) | After (PostgreSQL) |
|-----------|--------------------|--------------------|
| Server connection | `Server=localhost` | `Host=localhost` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | Removed (not applicable) |
| TLS | `TrustServerCertificate=True` | Removed (not applicable) |

## SQL Syntax Conversion Summary

| MS SQL Server Syntax | PostgreSQL Equivalent |
|---------------------|----------------------|
| `SCOPE_IDENTITY()` | `RETURNING productid` (with writable CTE) |
| `GETDATE()` | `clock_timestamp()` |
| `BEGIN TRANSACTION / COMMIT` | Writable CTE (single atomic statement) |
| `DECLARE @var TYPE; SET @var = expr` | CTE subquery (`WITH old_values AS (SELECT ...)`) |
| `dbo.Products` | `productmanagement_dbo.products` |
| PascalCase columns | lowercase columns |

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| Extracted Statements | `sourceCode/extracted_statements.sql` | 7 original MS SQL statements with source attribution |
| Converted Statements | `sourceCode/converted_statements.sql` | 7 converted PostgreSQL statements |
| Equivalency Report | `sourceCode/sql_equivalency_validation_report.json` | JSON report with all 7 statement pairs and tool results |
| Migration Report | `sourceCode/migration_report.md` | This comprehensive human-readable report |

## Final Validation Checklist

- [x] All Microsoft.Data.SqlClient references replaced with Npgsql
- [x] All SqlConnection/SqlCommand/SqlDataReader replaced with Npgsql equivalents
- [x] All 7 SQL statements converted to PostgreSQL syntax
- [x] All connection strings updated to PostgreSQL format
- [x] Package reference updated from Microsoft.Data.SqlClient to Npgsql
- [x] Project builds successfully (0 errors)
- [x] All 7 SQL statement pairs documented in equivalency report
- [x] DMS tool attempted for all 7 statements (all failed, documented)
- [x] SQL Equivalency tool used for all 7 pairs (all returned ERROR, documented)
- [x] Schema mapping obtained from DMS (successful) and applied consistently

## Build Status
- **Final Build**: SUCCESS
- **Errors**: 0
- **Warnings**: 10 (all pre-existing nullable reference type warnings)
