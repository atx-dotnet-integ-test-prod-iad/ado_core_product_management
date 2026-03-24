# Migration Log - SQL Server to PostgreSQL

## Migration Date: 2026-03-24
## Source: DataAccess/ProductRepository.cs
## Total SQL Statements: 7

---

### Statement 1: GetAllProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: GetAllProductsAsync()
- **Line Range**: ~47-68
- **Parameters**: None
- **DMS Invocation**: schema_name='dbo', migration_project='arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU'
- **DMS Status**: FAILED
- **DMS Error**: Metadata model creation failed: Statement definition is not valid.
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Manual Conversion Notes**: Statement already uses PostgreSQL syntax (::numeric cast, lowercase schema objects). No changes required.
- **Equivalency Validation**: ERROR - Tool returned: {'equivalence_status': 'ERROR', 'error': "'uniqueID'"}

---

### Statement 2: GetProductByIdAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: GetProductByIdAsync(int productId)
- **Line Range**: ~82-109
- **Parameters**: @ProductId (int)
- **DMS Invocation**: schema_name='dbo', migration_project='arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU'
- **DMS Status**: FAILED
- **DMS Error**: Metadata model creation failed: Statement definition is not valid.
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Manual Conversion Notes**: Statement already uses PostgreSQL syntax (::numeric cast, LAG window function, lowercase schema objects). No changes required.
- **Equivalency Validation**: ERROR - Tool returned: {'equivalence_status': 'ERROR', 'error': "'uniqueID'"}

---

### Statement 3: InsertProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: InsertProductAsync(Product product)
- **Line Range**: ~131-151
- **Parameters**: @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
- **DMS Invocation**: schema_name='dbo', migration_project='arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU'
- **DMS Status**: FAILED
- **DMS Error**: Metadata model creation failed: Statement definition is not valid.
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Manual Conversion Notes**: Statement already uses PostgreSQL syntax (RETURNING clause, NOW(), writable CTEs, lowercase schema objects). No changes required.
- **Equivalency Validation**: ERROR - Tool returned: {'equivalence_status': 'ERROR', 'error': "'uniqueID'"}

---

### Statement 4: UpdateProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: UpdateProductAsync(Product product)
- **Line Range**: ~168-196
- **Parameters**: @ProductId (int), @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
- **DMS Invocation**: schema_name='dbo', migration_project='arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU'
- **DMS Status**: FAILED
- **DMS Error**: Metadata model creation failed: Statement definition is not valid.
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Manual Conversion Notes**: Statement already uses PostgreSQL syntax (DO $$ anonymous block, SELECT INTO, NOW(), lowercase schema objects). No changes required.
- **Equivalency Validation**: ERROR - Tool returned: {'equivalence_status': 'ERROR', 'error': "'uniqueID'"}

---

### Statement 5: DeleteProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: DeleteProductAsync(int productId)
- **Line Range**: ~215-240
- **Parameters**: @ProductId (int)
- **DMS Invocation**: schema_name='dbo', migration_project='arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU'
- **DMS Status**: FAILED
- **DMS Error**: Metadata model creation failed: Statement definition is not valid.
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Manual Conversion Notes**: Statement already uses PostgreSQL syntax (DO $$ anonymous block, SELECT INTO, NOW(), CASE in UPDATE, lowercase schema objects). No changes required.
- **Equivalency Validation**: ERROR - Tool returned: {'equivalence_status': 'ERROR', 'error': "'uniqueID'"}

---

### Statement 6: GetProductsByPriceRangeAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
- **Line Range**: ~256-272
- **Parameters**: @MinPrice (decimal), @MaxPrice (decimal)
- **DMS Invocation**: schema_name='dbo', migration_project='arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU'
- **DMS Status**: FAILED
- **DMS Error**: Metadata model conversion failed: ConnectTimeout to dms.us-east-1.amazonaws.com
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Manual Conversion Notes**: Statement already uses PostgreSQL-compatible syntax (RANK, PERCENT_RANK window functions, BETWEEN, CASE, lowercase schema objects). No changes required.
- **Equivalency Validation**: ERROR - Tool returned: {'equivalence_status': 'ERROR', 'error': "'uniqueID'"}

---

### Statement 7: GetLowStockProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: GetLowStockProductsAsync(int threshold)
- **Line Range**: ~294-312
- **Parameters**: @Threshold (int)
- **DMS Invocation**: schema_name='dbo', migration_project='arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU'
- **DMS Status**: FAILED
- **DMS Error**: Metadata model creation did not complete after 15 attempts
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Manual Conversion Notes**: Statement already uses PostgreSQL syntax (::numeric cast, AVG/MIN/MAX window functions, lowercase schema objects). No changes required.
- **Equivalency Validation**: ERROR - Tool returned: {'equivalence_status': 'ERROR', 'error': "'uniqueID'"}

---

## Summary
- **Total Statements**: 7
- **DMS Successful Conversions**: 0
- **DMS Failed Conversions**: 7
- **Manual Conversions Applied**: 7 (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
- **Equivalency Validated (EQUIVALENT)**: 0
- **Equivalency Validated (NOT_EQUIVALENT)**: 0
- **Equivalency Validated (ERROR)**: 7
- **Note**: All statements were already partially migrated to PostgreSQL syntax. DMS failures are likely due to the statements already containing PostgreSQL-specific syntax (::numeric casts, DO $$ blocks, RETURNING clause, NOW() function) which are not valid SQL Server syntax that DMS expects as input.
- **Note**: SQL Equivalency tool returned ERROR for all 7 statements with error "'uniqueID'" - this appears to be an internal tool error, not related to statement validity.
