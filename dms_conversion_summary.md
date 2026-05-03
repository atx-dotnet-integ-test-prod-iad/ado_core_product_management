# DMS Conversion Summary

## Overview
All 25 SQL statements were submitted to the DMS MCP tool (dms-mcp___statement_conversion_tool) for conversion from MS SQL Server to PostgreSQL.
All 25 statements failed with the same error.

## DMS Configuration Used
- migration_project_identifier: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU
- database_name: ProductManagement
- schema_name: dbo
- region: us-east-1
- server_name: 172.31.94.132

## DMS Error
All 25 statements returned:
```
status: "error"
error: "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
```

## Fallback Approach
Per the transformation definition, since DMS failed, manual conversion was applied using:
- conversion_method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- All schema object names converted to lowercase for PostgreSQL compatibility
- Key MS SQL Server → PostgreSQL conversions applied:
  - IDENTITY(1,1) → GENERATED ALWAYS AS IDENTITY
  - nvarchar(n) → VARCHAR(n)
  - datetime → TIMESTAMP
  - bit → BOOLEAN
  - decimal(p,s) → NUMERIC(p,s)
  - GETDATE() → CURRENT_TIMESTAMP
  - clock_timestamp() used where real-time timestamps needed (within transactions)
  - SCOPE_IDENTITY() → RETURNING clause
  - CREATE OR ALTER PROCEDURE → CREATE OR REPLACE FUNCTION (plpgsql)
  - CREATE TRIGGER (SQL Server) → CREATE FUNCTION + CREATE TRIGGER (PostgreSQL)
  - SYSTEM_USER → CURRENT_USER
  - EXEC procedure → SELECT function()
  - GO → removed (semicolons used)
  - SET NOCOUNT ON → removed (not needed in PostgreSQL)
  - [dbo].[TableName] → lowercase tablename
  - IsDiscontinued = 1 → isdiscontinued = TRUE

## Statements Processed
| Statement # | Source | Type | DMS Status | Manual Conversion |
|---|---|---|---|---|
| 1 | ProductRepository.cs - GetAllProductsAsync | SELECT with CTE | FAILED | Applied lowercase |
| 2 | ProductRepository.cs - GetProductByIdAsync | SELECT with CTE | FAILED | Applied lowercase |
| 3 | ProductRepository.cs - InsertProductAsync | Transaction block | FAILED | Applied lowercase + RETURNING |
| 4 | ProductRepository.cs - UpdateProductAsync | Transaction block | FAILED | Applied lowercase + clock_timestamp |
| 5 | ProductRepository.cs - DeleteProductAsync | Transaction block | FAILED | Applied lowercase + clock_timestamp |
| 6 | ProductRepository.cs - GetProductsByPriceRangeAsync | SELECT with CTE | FAILED | Applied lowercase |
| 7 | ProductRepository.cs - GetLowStockProductsAsync | SELECT with CTE | FAILED | Applied lowercase + NUMERIC |
| 8 | Scripts - Create Products Table (Simple) | DDL | FAILED | Full type conversion |
| 9 | Scripts - sp_GetAllProducts | DDL Procedure | FAILED | Converted to FUNCTION |
| 10 | Scripts - sp_GetProductById | DDL Procedure | FAILED | Converted to FUNCTION |
| 11 | Scripts - sp_InsertProduct | DDL Procedure | FAILED | Converted to FUNCTION + RETURNING |
| 12 | Scripts - sp_UpdateProduct | DDL Procedure | FAILED | Converted to FUNCTION |
| 13 | Scripts - sp_DeleteProduct | DDL Procedure | FAILED | Converted to FUNCTION |
| 14 | Scripts - Insert Sample Data | DML EXEC | FAILED | Converted to SELECT function() |
| 15 | Database - Create Categories Table | DDL | FAILED | Full type conversion |
| 16 | Database - Create Suppliers Table | DDL | FAILED | Full type conversion + BOOLEAN |
| 17 | Database - Create Products Table (Complex) | DDL | FAILED | Full type conversion + FK |
| 18 | Database - Create ProductHistory Table | DDL | FAILED | Full type conversion + FK |
| 19 | Database - Create ProductStats Table | DDL | FAILED | Full type conversion |
| 20 | Database - Insert Categories | DML | FAILED | Applied lowercase |
| 21 | Database - Insert Suppliers | DML | FAILED | Applied lowercase |
| 22 | Database - Insert Products | DML | FAILED | Applied lowercase |
| 23 | Database - Insert Stats | DML | FAILED | Applied lowercase + CURRENT_TIMESTAMP |
| 24 | Database - Update Stats | DML | FAILED | Applied lowercase + CURRENT_TIMESTAMP + BOOLEAN |
| 25 | Database - Create Trigger | DDL Trigger | FAILED | Converted to FUNCTION + TRIGGER |
