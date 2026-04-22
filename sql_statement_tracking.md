# SQL Statement Tracking Document

## Source File: sourceCode/DataAccess/ProductRepository.cs

| # | Method Name | Line Range | SQL Type | Key SQL Server Constructs |
|---|-------------|-----------|----------|--------------------------|
| 1 | GetAllProductsAsync | ~44-67 | SELECT (CTE) | AVG() OVER, COUNT(*) OVER, INNER JOIN, CASE, ROUND, ORDER BY CASE |
| 2 | GetProductByIdAsync | ~75-101 | SELECT (CTE) | LAG() OVER, LEFT JOIN, CASE with NULL, ROUND, @ProductId param |
| 3 | InsertProductAsync | ~112-133 | Transaction Block | DECLARE, BEGIN TRANSACTION/COMMIT, INSERT, SCOPE_IDENTITY(), GETDATE() |
| 4 | UpdateProductAsync | ~142-171 | Transaction Block | DECLARE, SELECT into vars, UPDATE, INSERT, GETDATE() |
| 5 | DeleteProductAsync | ~179-213 | Transaction Block | DECLARE, SELECT into vars, INSERT, DELETE, CASE, GETDATE() |
| 6 | GetProductsByPriceRangeAsync | ~253-273 | SELECT (CTE) | RANK() OVER, PERCENT_RANK() OVER, BETWEEN, CASE |
| 7 | GetLowStockProductsAsync | ~293-315 | SELECT (CTE) | AVG/MIN/MAX() OVER, CASE, ROUND |

## Tables Referenced
- Products (main table)
- ProductHistory (audit/history table)
- ProductStats (statistics table)

## Parameter Summary
- @ProductId: Used in statements 2, 4, 5
- @Name, @Description, @Price, @StockQuantity: Used in statements 3, 4
- @MinPrice, @MaxPrice: Used in statement 6
- @Threshold: Used in statement 7

## SQL Server-Specific Constructs Requiring Conversion
1. **SCOPE_IDENTITY()** → PostgreSQL equivalent (RETURNING clause or lastval())
2. **GETDATE()** → NOW() or CURRENT_TIMESTAMP
3. **BEGIN TRANSACTION / COMMIT** → BEGIN / COMMIT
4. **DECLARE @variable** → PostgreSQL variable syntax or DO block
5. **Window functions** (LAG, RANK, PERCENT_RANK) → Should be compatible
6. **ROUND()** → May need cast adjustments for integer division
7. **BETWEEN** → Compatible
