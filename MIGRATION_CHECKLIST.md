# ADO.NET SQL Server to PostgreSQL Migration Checklist

**Project:** AdoCore  
**Migration Type:** ADO.NET (Non-Entity Framework)  
**Target Database:** PostgreSQL (postgres)  
**Framework:** .NET 9.0

---

## ✅ Completed Migration Tasks

### 1. Package References ✅

#### Files Modified:
- `AdoCore.csproj`

#### Changes:
- ✅ Removed `Microsoft.Data.SqlClient` package
- ✅ Removed `System.Data.SqlClient` package (if present)
- ✅ Added `Npgsql` version 8.0.5
- ✅ Retained `Microsoft.Extensions.Configuration` version 8.0.0
- ✅ Retained `Microsoft.Extensions.Configuration.Json` version 8.0.0
- ✅ Retained `Microsoft.Extensions.DependencyInjection` version 8.0.0
- ✅ Verified .NET 9.0 target framework compatibility

**Package Version Compatibility:**
- Npgsql 8.0.5 is compatible with .NET 9.0 ✅
- All Microsoft.Extensions.* packages are compatible with .NET 9.0 ✅

---

### 2. Connection Strings ✅

#### Files Modified:
- `appsettings.json`

#### Changes:

**DevConnection:**
- **Before:** `Server=...;Database=...;User Id=...` (SQL Server format)
- **After:** `Host=localhost;Database=postgres;Username=postgres;Password=postgres;` ✅

**ProdConnection:**
- **Before:** `Server=...;Database=...;User Id=...` (SQL Server format)
- **After:** `Host=localhost;Database=postgres;Username=postgres;Password=postgres;` ✅

**Target Database:**
- Retrieved from DMS: `postgres` ✅
- Applied to all connection strings ✅

**Connection String Format Verification:**
- ✅ Uses `Host=` instead of `Server=` or `Data Source=`
- ✅ Uses `Database=` instead of `Initial Catalog=`
- ✅ Uses `Username=` instead of `User ID=` or `User Id=`
- ✅ Uses `Password=` parameter
- ✅ No SQL Server-specific parameters (Integrated Security, TrustServerCertificate, etc.)

---

### 3. Using Statements ✅

#### Files Modified:
- `DataAccess/ProductRepository.cs`

#### Changes:
- ✅ Added `using Npgsql;`
- ✅ Removed `using Microsoft.Data.SqlClient;`
- ✅ Removed `using System.Data.SqlClient;`
- ✅ Retained `using System.Data;` (for ConnectionState, etc.)
- ✅ Retained `using Microsoft.Extensions.Configuration;`

---

### 4. ADO.NET Components ✅

#### Files Modified:
- `DataAccess/ProductRepository.cs`

#### Connection Objects:
- **Before:** `SqlConnection`
- **After:** `NpgsqlConnection` ✅
- **Occurrences:** 17 instances updated

**Methods Updated:**
- ✅ `GetConnectionAsync()` - Returns `Task<NpgsqlConnection>`
- ✅ Private field `_connection` - Type `NpgsqlConnection`
- ✅ All methods that create connections

#### Command Objects:
- **Before:** `SqlCommand`
- **After:** `NpgsqlCommand` ✅
- **Occurrences:** 14 instances updated

**Methods Updated:**
- ✅ `GetAllProductsAsync()` - Uses `new NpgsqlCommand()`
- ✅ `GetProductByIdAsync()` - Uses `new NpgsqlCommand()`
- ✅ `InsertProductAsync()` - Uses `new NpgsqlCommand()` (multiple times)
- ✅ `UpdateProductAsync()` - Uses `new NpgsqlCommand()` (multiple times)
- ✅ `DeleteProductAsync()` - Uses `new NpgsqlCommand()` (multiple times)
- ✅ `GetProductsByPriceRangeAsync()` - Uses `new NpgsqlCommand()`
- ✅ `GetLowStockProductsAsync()` - Uses `new NpgsqlCommand()`

#### DataReader Objects:
- **Before:** `SqlDataReader`
- **After:** `NpgsqlDataReader` ✅
- **Occurrences:** 3 instances updated

**Methods Updated:**
- ✅ `MapProductFromReader(NpgsqlDataReader reader)` - Parameter type updated
- ✅ All methods using `ExecuteReaderAsync()`

#### Transaction Objects:
- **Before:** Implicit SQL Server transaction
- **After:** `NpgsqlTransaction` ✅
- **Methods:** `BeginTransactionAsync()`, `CommitAsync()`, `RollbackAsync()`

---

### 5. SQL Syntax Transformations ✅

#### Files Modified:
- `DataAccess/ProductRepository.cs`

#### Date/Time Functions:

**GETDATE() → CURRENT_TIMESTAMP:**

| Method | Line | Transformation | Status |
|--------|------|----------------|--------|
| InsertProductAsync | 141 | `ActionDate = CURRENT_TIMESTAMP` | ✅ |
| InsertProductAsync | 158 | `LastUpdated = CURRENT_TIMESTAMP` | ✅ |
| UpdateProductAsync | 207 | `ModifiedDate = CURRENT_TIMESTAMP` | ✅ |
| UpdateProductAsync | 218 | `ActionDate = CURRENT_TIMESTAMP` | ✅ |
| UpdateProductAsync | 228 | `LastUpdated = CURRENT_TIMESTAMP` | ✅ |
| DeleteProductAsync | 265 | `ActionDate = CURRENT_TIMESTAMP` | ✅ |

**Verification:** ❌ No remaining instances of `GETDATE()` found ✅

#### Identity Retrieval:

**SCOPE_IDENTITY() → RETURNING:**

| Method | Line | Transformation | Status |
|--------|------|----------------|--------|
| InsertProductAsync | 130 | `RETURNING ProductId` | ✅ |

**Implementation Details:**
```csharp
const string insertSql = @"
    INSERT INTO public.products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId";

newProductId = Convert.ToInt32(await command.ExecuteScalarAsync());
```

**Verification:** ❌ No remaining instances of `SCOPE_IDENTITY()` found ✅

#### Schema Qualification:

**[dbo].[TableName] → public.tablename:**

| Table Reference | Occurrences | Status |
|----------------|-------------|--------|
| `public.products` | 41+ | ✅ |
| `public.producthistory` | 5 | ✅ |
| `public.productstats` | 3 | ✅ |

**All SQL queries use fully-qualified table names.**

---

### 6. Complex SQL Features ✅

#### Common Table Expressions (CTEs):

| Method | CTE Name | Window Functions Used | Status |
|--------|----------|----------------------|--------|
| GetAllProductsAsync | ProductStats | AVG() OVER(), COUNT() OVER() | ✅ |
| GetProductByIdAsync | ProductHistory | LAG() OVER() | ✅ |
| GetProductsByPriceRangeAsync | RankedProducts | RANK() OVER(), PERCENT_RANK() OVER() | ✅ |
| GetLowStockProductsAsync | StockAnalysis | AVG/MIN/MAX() OVER() | ✅ |

**All CTEs verified as PostgreSQL-compatible.**

#### Window Functions:

| Function | Usage | PostgreSQL Compatible | Status |
|----------|-------|----------------------|--------|
| AVG() OVER() | GetAllProductsAsync | Yes | ✅ |
| COUNT() OVER() | GetAllProductsAsync | Yes | ✅ |
| LAG() OVER() | GetProductByIdAsync | Yes | ✅ |
| RANK() OVER() | GetProductsByPriceRangeAsync | Yes | ✅ |
| PERCENT_RANK() OVER() | GetProductsByPriceRangeAsync | Yes | ✅ |
| MIN() OVER() | GetLowStockProductsAsync | Yes | ✅ |
| MAX() OVER() | GetLowStockProductsAsync | Yes | ✅ |

**All window functions verified as PostgreSQL-compatible.**

#### Transaction Handling:

| Method | Transaction Features | Status |
|--------|---------------------|--------|
| InsertProductAsync | Multi-statement transaction | ✅ |
| UpdateProductAsync | Multi-statement transaction | ✅ |
| DeleteProductAsync | Multi-statement transaction | ✅ |
| ExecuteInTransactionAsync | Generic transaction wrapper | ✅ |

**Transaction Pattern:**
```csharp
using var transaction = await connection.BeginTransactionAsync();
try
{
    // Multiple SQL operations
    await transaction.CommitAsync();
}
catch
{
    await transaction.RollbackAsync();
    throw;
}
```

**All transactions use PostgreSQL-compatible async patterns.**

---

### 7. Configuration Files ✅

#### Application Configuration:

**File:** `appsettings.json`
- ✅ PostgreSQL connection strings configured
- ✅ Environment setting present
- ✅ No SQL Server remnants
- ✅ JSON format valid

**File:** `AdoCore.csproj`
- ✅ Npgsql package reference added
- ✅ SQL Server packages removed
- ✅ Configuration packages present
- ✅ Target framework set to net9.0
- ✅ appsettings.json marked as "Copy to output directory"

---

### 8. Other Source Files Verification ✅

#### Business Layer:

**File:** `Business/ProductService.cs`
- ✅ No direct database access (uses repository abstraction)
- ✅ No SQL Server-specific code
- ✅ Validation logic is database-agnostic
- ✅ No changes required

#### Models:

**File:** `Models/Product.cs`
- ✅ POCO class with no database attributes
- ✅ Compatible with both SQL Server and PostgreSQL
- ✅ DateTime handling is framework-level
- ✅ No changes required

#### Application Entry Point:

**File:** `Program.cs`
- ✅ Uses dependency injection
- ✅ Configuration loaded from appsettings.json
- ✅ No database-specific code
- ✅ Service registration is database-agnostic
- ✅ No changes required

#### CLI Layer:

**Files:** `CLI/CommandLineInterface.cs`, `CLI/InteractiveMenu.cs`
- ✅ No direct database access
- ✅ Uses service layer abstraction
- ✅ No changes required

---

## ⚠️ Manual Steps Required

### 1. Database Setup Scripts Conversion ⚠️

#### Files Requiring Conversion:
- `Database/Scripts/01_InitialSetup.sql` (Extended schema with categories, suppliers, etc.)
- `Scripts/01_InitialSetup.sql` (Simplified schema)

#### Required Transformations:

| SQL Server Syntax | PostgreSQL Syntax | Priority |
|------------------|-------------------|----------|
| `IDENTITY(1,1)` | `SERIAL` or `GENERATED ALWAYS AS IDENTITY` | High |
| `GETDATE()` | `CURRENT_TIMESTAMP` or `NOW()` | High |
| `NVARCHAR(n)` | `VARCHAR(n)` or `TEXT` | High |
| `[dbo].[TableName]` | `public.table_name` | High |
| `GO` | `;` or remove | High |
| `IF EXISTS (SELECT * FROM sys.databases ...)` | PostgreSQL catalog queries | High |
| `IF EXISTS (SELECT * FROM sys.objects ...)` | PostgreSQL catalog queries | High |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` | Medium |
| Triggers | PostgreSQL trigger syntax | Medium |
| `SET NOCOUNT ON` | Remove (not needed) | Low |

#### Specific Items:

**Tables to Convert:**
- ⚠️ Categories table
- ⚠️ Suppliers table
- ⚠️ Products table
- ⚠️ ProductHistory table
- ⚠️ ProductStats table

**Stored Procedures (Optional - Not Used by Application):**
- ⚠️ sp_GetAllProducts
- ⚠️ sp_GetProductById
- ⚠️ sp_InsertProduct
- ⚠️ sp_UpdateProduct
- ⚠️ sp_DeleteProduct

**Note:** The application does NOT call stored procedures. It uses inline SQL in `ProductRepository.cs`. Converting stored procedures is optional.

**Triggers (Optional - Not Used by Application):**
- ⚠️ trg_Products_History

**Note:** The application implements history logging in code, not via triggers. Converting the trigger is optional.

**Indexes:**
- ⚠️ IX_Products_CategoryId
- ⚠️ IX_Products_SupplierId
- ⚠️ IX_Products_SKU (unique)
- ⚠️ IX_ProductHistory_ProductId
- ⚠️ IX_ProductHistory_ActionDate

**Sample Data:**
- ⚠️ Categories (20 rows)
- ⚠️ Suppliers (8 rows)
- ⚠️ Products (19 rows)
- ⚠️ ProductStats (1 row)

---

### 2. Database Creation and Schema Deployment ⚠️

#### Step-by-Step Instructions:

**Step 1: Create PostgreSQL Database**
```bash
# Connect to PostgreSQL server
psql -U postgres -h localhost

# Create database (if not exists)
CREATE DATABASE postgres;

# Exit
\q
```

**Step 2: Run Converted Schema Script**
```bash
# After converting the SQL script to PostgreSQL syntax
psql -U postgres -d postgres -f Scripts/01_InitialSetup_PostgreSQL.sql
```

**Step 3: Verify Schema Creation**
```bash
psql -U postgres -d postgres

# List tables
\dt public.*

# Expected tables:
# - public.categories
# - public.suppliers
# - public.products
# - public.producthistory
# - public.productstats

# List indexes
\di public.*

# Exit
\q
```

**Step 4: Verify Sample Data**
```sql
SELECT COUNT(*) FROM public.products;
-- Expected: 19 rows

SELECT COUNT(*) FROM public.categories;
-- Expected: 20 rows

SELECT COUNT(*) FROM public.suppliers;
-- Expected: 8 rows
```

---

### 3. Production Connection String Configuration ⚠️

#### AWS Secrets Manager Integration:

**Target Secret ARN:**
```
arn:aws:secretsmanager:us-east-1:789616364195:secret:atx-db-modernization-jaabou-DBConnector-setup-ProductManagement-source-target-t0337O
```

**Option 1: CloudFormation/CDK Token Resolution**

Update `appsettings.Production.json`:
```json
{
  "ConnectionStrings": {
    "ProdConnection": "Host={{resolve:secretsmanager:arn:aws:secretsmanager:us-east-1:789616364195:secret:atx-db-modernization-jaabou-DBConnector-setup-ProductManagement-source-target-t0337O:SecretString:host}};Database=postgres;Username={{resolve:secretsmanager:arn:aws:secretsmanager:us-east-1:789616364195:secret:atx-db-modernization-jaabou-DBConnector-setup-ProductManagement-source-target-t0337O:SecretString:username}};Password={{resolve:secretsmanager:arn:aws:secretsmanager:us-east-1:789616364195:secret:atx-db-modernization-jaabou-DBConnector-setup-ProductManagement-source-target-t0337O:SecretString:password}};"
  }
}
```

**Option 2: Environment Variables**

Update `ProductRepository.cs` constructor:
```csharp
public ProductRepository(IConfiguration configuration)
{
    _configuration = configuration;
    var environment = _configuration["Environment"];
    
    if (environment == "Production")
    {
        // Use environment variables in production
        var host = Environment.GetEnvironmentVariable("DB_HOST");
        var username = Environment.GetEnvironmentVariable("DB_USERNAME");
        var password = Environment.GetEnvironmentVariable("DB_PASSWORD");
        var database = Environment.GetEnvironmentVariable("DB_NAME") ?? "postgres";
        
        _connectionString = $"Host={host};Database={database};Username={username};Password={password};";
    }
    else
    {
        // Use connection string from appsettings in dev/test
        var connectionName = environment == "Production" ? "ProdConnection" : "DevConnection";
        _connectionString = _configuration.GetConnectionString(connectionName);
    }
}
```

**Set environment variables:**
```bash
export DB_HOST="your-postgres-host.amazonaws.com"
export DB_USERNAME="postgres"
export DB_PASSWORD="$(aws secretsmanager get-secret-value --secret-id arn:aws:secretsmanager:us-east-1:789616364195:secret:atx-db-modernization-jaabou-DBConnector-setup-ProductManagement-source-target-t0337O --query SecretString --output text | jq -r .password)"
export DB_NAME="postgres"
```

**Option 3: AWS Secrets Manager SDK**

Add package reference:
```xml
<PackageReference Include="AWSSDK.SecretsManager" Version="3.7.0" />
```

Implement secret retrieval:
```csharp
using Amazon.SecretsManager;
using Amazon.SecretsManager.Model;
using System.Text.Json;

private async Task<string> GetSecretConnectionString()
{
    var secretArn = "arn:aws:secretsmanager:us-east-1:789616364195:secret:atx-db-modernization-jaabou-DBConnector-setup-ProductManagement-source-target-t0337O";
    
    using var client = new AmazonSecretsManagerClient(Amazon.RegionEndpoint.USEast1);
    var request = new GetSecretValueRequest { SecretId = secretArn };
    var response = await client.GetSecretValueAsync(request);
    
    var secret = JsonSerializer.Deserialize<Dictionary<string, string>>(response.SecretString);
    
    return $"Host={secret["host"]};Database=postgres;Username={secret["username"]};Password={secret["password"]};";
}
```

---

### 4. Application Testing ⚠️

#### Build and Run:

**Step 1: Restore Packages**
```bash
cd /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode
dotnet restore
```

**Step 2: Build Application**
```bash
dotnet build
```

**Expected Output:**
```
Build succeeded.
    0 Warning(s)
    0 Error(s)
```

**Step 3: Run Application**
```bash
dotnet run
```

**Expected Behavior:**
- Application starts without errors
- Interactive menu appears
- Can connect to PostgreSQL database

#### Test CRUD Operations:

**Test 1: List All Products**
```bash
dotnet run -- list
```

**Expected:**
- Query executes successfully
- Returns products from database
- CTE with window functions works

**Test 2: Get Product by ID**
```bash
dotnet run -- get 1
```

**Expected:**
- Query executes successfully
- Returns product details
- LAG() window function works

**Test 3: Insert Product**
```bash
dotnet run -- add "Test Product" "Test Description" 99.99 10
```

**Expected:**
- Transaction executes successfully
- RETURNING clause returns new ID
- History logging works
- Statistics update works
- Transaction commits

**Test 4: Update Product**
```bash
dotnet run -- update 1 "Updated Name" "Updated Description" 199.99 20
```

**Expected:**
- Transaction executes successfully
- CURRENT_TIMESTAMP used for modified date
- History logging works
- Statistics update works
- Transaction commits

**Test 5: Delete Product**
```bash
dotnet run -- delete 1
```

**Expected:**
- Transaction executes successfully
- History logging works
- Statistics update works
- Transaction commits

**Test 6: Price Range Query**
```bash
dotnet run -- range 50 150
```

**Expected:**
- CTE with RANK() and PERCENT_RANK() works
- Returns products in price range

**Test 7: Low Stock Query**
```bash
dotnet run -- lowstock 10
```

**Expected:**
- CTE with multiple aggregate window functions works
- Returns products below threshold

---

### 5. Performance Optimization ⚠️

#### Indexes:

Verify indexes are created:
```sql
-- Check existing indexes
SELECT indexname, tablename 
FROM pg_indexes 
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
```

Create additional indexes if needed:
```sql
-- Index on Price for range queries
CREATE INDEX idx_products_price ON public.products(price);

-- Index on StockQuantity for low stock queries
CREATE INDEX idx_products_stock ON public.products(stockquantity);

-- Index on CreatedDate for time-based queries
CREATE INDEX idx_products_created ON public.products(createddate);
```

#### Connection Pooling:

Add to connection string:
```
Host=localhost;Database=postgres;Username=postgres;Password=postgres;Pooling=true;MinPoolSize=5;MaxPoolSize=100;
```

#### Query Analysis:

```sql
-- Enable query timing
\timing

-- Analyze query plan
EXPLAIN ANALYZE
WITH ProductStats AS (
    SELECT 
        ProductId,
        AVG(Price) OVER() as AvgPrice,
        COUNT(*) OVER() as TotalProducts
    FROM public.products
)
SELECT * FROM ProductStats;
```

#### PostgreSQL Configuration:

Optimize postgresql.conf:
```ini
# Memory settings
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 16MB

# Connection settings
max_connections = 100

# Query planning
random_page_cost = 1.1  # For SSD storage
effective_io_concurrency = 200
```

---

## Summary

### ✅ Completed (Code Level):

1. ✅ Package references updated (Npgsql 8.0.5)
2. ✅ Connection strings transformed to PostgreSQL format
3. ✅ Using statements updated (Npgsql)
4. ✅ ADO.NET components migrated (NpgsqlConnection, NpgsqlCommand, NpgsqlDataReader)
5. ✅ SQL syntax transformed (GETDATE → CURRENT_TIMESTAMP, SCOPE_IDENTITY → RETURNING)
6. ✅ Schema qualification added (public.)
7. ✅ Complex SQL features verified (CTEs, window functions, transactions)
8. ✅ Configuration files verified
9. ✅ Other source files verified (no changes needed)

### ⚠️ Manual Steps Required:

1. ⚠️ Convert database setup scripts to PostgreSQL syntax
2. ⚠️ Create PostgreSQL database and run converted scripts
3. ⚠️ Configure production connection strings (AWS Secrets Manager)
4. ⚠️ Build and test application against PostgreSQL
5. ⚠️ Optimize performance (indexes, connection pooling, query tuning)
6. ⚠️ Deploy to production environment
7. ⚠️ Monitor and validate application behavior

### Recommended Next Steps:

1. **Immediate:** Convert database setup scripts (see Section 1)
2. **Immediate:** Create PostgreSQL database and schema (see Section 2)
3. **Short-term:** Test application locally (see Section 4)
4. **Short-term:** Configure AWS Secrets Manager integration (see Section 3)
5. **Medium-term:** Performance optimization (see Section 5)
6. **Long-term:** Production deployment and monitoring

---

**Checklist Generated:** 2024  
**Migration Status:** Code migration complete, database setup pending  
**Next Action:** Convert SQL scripts to PostgreSQL syntax
