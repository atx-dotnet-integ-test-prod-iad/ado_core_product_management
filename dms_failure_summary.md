# DMS Failure Summary

## Overview
All 43 SQL statements were attempted through the DMS MCP Statement Conversion Tool (`dms-mcp___statement_conversion_tool`). Every single attempt failed with the same error.

## DMS Configuration Used
- **Migration Project ARN**: `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`
- **Schema Name**: `dbo`
- **Database Name**: `ProductManagement`
- **Region**: `us-east-1`
- **Server Name**: `172.31.94.132`

## Error Details
- **Status**: `error`
- **Error Message**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Error occurs at workflow step**: `create_metadata_model`

## DMS Schema Mapping Tool (Successful)
While the statement conversion tool failed, the DMS Schema Mapping Tool (`dms-mcp___schema_mapping_tool`) worked successfully and provided target DDL for all tables:
- `Products` → `products` (schema: `productmanagement_dbo`)
- `ProductHistory` → `producthistory` (schema: `productmanagement_dbo`)
- `ProductStats` → `productstats` (schema: `productmanagement_dbo`)
- `Categories` → `categories` (schema: `productmanagement_dbo`)
- `Suppliers` → `suppliers` (schema: `productmanagement_dbo`)

## Manual Conversion Applied
Since DMS failed, manual conversion was applied with the following rules (per transformation definition):
- **Reason**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- All schema object names (tables, columns, aliases) converted to lowercase
- MS SQL Server functions mapped to PostgreSQL equivalents:
  - `GETDATE()` → `NOW()`
  - `SCOPE_IDENTITY()` → `RETURNING productid`
  - `IDENTITY(1,1)` → `GENERATED ALWAYS AS IDENTITY`
  - `nvarchar` → `VARCHAR`
  - `bit` → `BOOLEAN`
  - `datetime` → `TIMESTAMP WITHOUT TIME ZONE`
  - `SYSTEM_USER` → `current_user`
  - `CAST(x AS DECIMAL)` → `x::numeric`
- Stored procedures converted to PostgreSQL functions (`CREATE OR REPLACE FUNCTION`)
- Triggers converted to PostgreSQL `FUNCTION + TRIGGER` pattern

## Statements Attempted (All 43 Failed)

| Statement # | Description | DMS Result |
|---|---|---|
| 1 | GetAllProductsAsync CTE query | FAILED |
| 2 | GetProductByIdAsync CTE query | FAILED |
| 3 | InsertProductAsync - INSERT with SCOPE_IDENTITY() | FAILED |
| 4 | InsertProductAsync - INSERT into ProductHistory | FAILED |
| 5 | InsertProductAsync - UPDATE ProductStats | FAILED |
| 6 | UpdateProductAsync - SELECT | FAILED |
| 7 | UpdateProductAsync - UPDATE Products | FAILED |
| 8 | UpdateProductAsync - INSERT into ProductHistory | FAILED |
| 9 | UpdateProductAsync - UPDATE ProductStats | FAILED |
| 10 | DeleteProductAsync - SELECT | FAILED |
| 11 | DeleteProductAsync - INSERT into ProductHistory | FAILED |
| 12 | DeleteProductAsync - DELETE | FAILED |
| 13 | DeleteProductAsync - UPDATE ProductStats with CASE | FAILED |
| 14 | GetProductsByPriceRangeAsync CTE query | FAILED |
| 15 | GetLowStockProductsAsync CTE query | FAILED |
| 16 | CREATE TABLE Categories | FAILED |
| 17 | ALTER TABLE Categories FK | FAILED |
| 18 | CREATE TABLE Suppliers | FAILED |
| 19 | CREATE TABLE Products | FAILED |
| 20 | CREATE TABLE ProductHistory | FAILED |
| 21 | CREATE TABLE ProductStats | FAILED |
| 22-26 | CREATE INDEX statements (5) | FAILED |
| 27-29 | INSERT sample data (3) | FAILED |
| 30 | INSERT ProductStats initial record | FAILED |
| 31 | UPDATE ProductStats initial statistics | FAILED |
| 32 | CREATE TRIGGER trg_Products_History | FAILED |
| 33-37 | CREATE PROCEDURE statements (5) | FAILED |
| 38 | CREATE TABLE Products (Scripts version) | FAILED |
| 39-43 | CREATE PROCEDURE statements Scripts version (5) | FAILED |
