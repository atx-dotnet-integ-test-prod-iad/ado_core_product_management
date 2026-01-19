# SQL Statement Re-integration Notes for ProductRepository.cs

## Overview
This file documents the SQL statement replacements required in ProductRepository.cs.
All converted PostgreSQL statements are available in converted_statements.sql.
The key schema change is: ALL table references must use 'productmanagement_dbo.' prefix.

## Critical Schema Changes from DMS
- Products → productmanagement_dbo.products
- ProductHistory → productmanagement_dbo.producthistory  
- ProductStats → productmanagement_dbo.productstats
- All identifiers converted to lowercase (PostgreSQL convention)

## Statement-by-Statement Replacement Guide

### Statement 1: GetAllProductsAsync (Lines 42-69)
**Replace:** CTE name 'ProductStats' → 'productstats'
**Replace:** Table 'Products' → 'productmanagement_dbo.products'
**Replace:** All column names to lowercase (ProductId → productid, etc.)
**Add:** 'NULLS FIRST' to ORDER BY clauses
**Source:** converted_statements.sql, Statement 1

### Statement 2: GetProductByIdAsync (Lines 86-113)
**Replace:** CTE name 'ProductHistory' → 'producthistory'  
**Replace:** Table 'Products' → 'productmanagement_dbo.products'
**Replace:** LEFT JOIN → LEFT OUTER JOIN
**Replace:** All column names to lowercase
**Source:** converted_statements.sql, Statement 2

### Statement 3: InsertProductAsync (Lines 129-156)
**CRITICAL:** This requires code restructuring, not just SQL replacement
**Changes Required:**
1. Remove DECLARE @NewProductId and SELECT @NewProductId
2. Split into 3 separate SQL statements (INSERT with RETURNING, then 2 more statements)
3. Use RETURNING clause: INSERT...VALUES...RETURNING productid
4. Execute statements sequentially, capturing returned ID
5. Update table names to productmanagement_dbo prefix
6. Replace GETDATE() with CURRENT_TIMESTAMP
7. Transaction handled by C# BeginTransactionAsync(), not in SQL
**Source:** converted_statements.sql, Statement 3

### Statement 4: UpdateProductAsync (Lines 172-203)
**Changes Required:**
1. Remove BEGIN TRANSACTION / COMMIT (handled in C#)
2. Convert to DO $$ ... END $$ block format
3. DECLARE section uses var_OldPrice, var_OldStock
4. Replace table names with productmanagement_dbo prefix
5. Replace GETDATE() with clock_timestamp()
6. All column names to lowercase
**Source:** converted_statements.sql, Statement 4

### Statement 5: DeleteProductAsync (Lines 213-246)
**Changes Required:**
1. Remove BEGIN TRANSACTION / COMMIT (handled in C#)
2. Convert to DO $$ ... END $$ block format
3. DECLARE section uses var_OldPrice, var_OldStock
4. Replace table names with productmanagement_dbo prefix
5. Replace GETDATE() with clock_timestamp()
6. All column names to lowercase
**Source:** converted_statements.sql, Statement 5

### Statement 6: GetProductsByPriceRangeAsync (Lines 256-279)
**Replace:** CTE name 'RankedProducts' → 'rankedproducts'
**Replace:** Table 'Products' → 'productmanagement_dbo.products'
**Replace:** All column names to lowercase
**Add:** 'NULLS FIRST' to ORDER BY
**Source:** converted_statements.sql, Statement 6

### Statement 7: GetLowStockProductsAsync (Lines 289-312)
**Replace:** CTE name 'StockAnalysis' → 'stockanalysis'
**Replace:** Table 'Products' → 'productmanagement_dbo.products'
**Replace:** All column names to lowercase
**Add:** 'NULLS FIRST' to ORDER BY
**Source:** converted_statements.sql, Statement 7

## Implementation Status
- [ ] Statement 1 replacement
- [ ] Statement 2 replacement
- [ ] Statement 3 code restructuring
- [ ] Statement 4 replacement
- [ ] Statement 5 replacement
- [ ] Statement 6 replacement
- [ ] Statement 7 replacement

## Next Steps After SQL Replacement
1. Update package dependencies (Step 5) - Replace Microsoft.Data.SqlClient with Npgsql
2. Update ADO.NET classes (Step 6) - Replace SqlConnection/SqlCommand/etc with Npgsql equivalents
3. Update connection strings (Step 7) - Convert to PostgreSQL format
4. Generate final report (Step 8)

## Reference Files
- Original SQL: extracted_statements.sql
- Converted SQL: converted_statements.sql
- Conversion log: dms_conversion_log.json
- Equivalency report: sql_equivalency_validation_report.json
