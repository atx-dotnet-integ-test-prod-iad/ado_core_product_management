# Quick Reference: SQL Server to PostgreSQL Migration

**Project:** AdoCore | **Status:** ✅ Code Complete | **Next:** Database Setup

---

## 🚀 Quick Start (5 Minutes)

### 1. Verify Migration
```bash
cd /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode

# Check packages
grep "Npgsql" AdoCore.csproj
# Expected: <PackageReference Include="Npgsql" Version="8.0.5" />

# Check connection string
grep "Host=" appsettings.json
# Expected: "Host=localhost;Database=postgres;Username=postgres;Password=postgres;"

# Check code
grep "using Npgsql" DataAccess/ProductRepository.cs
# Expected: using Npgsql;
```

### 2. Setup Database
```bash
# Start PostgreSQL
sudo systemctl start postgresql  # Linux
# or
net start postgresql-x64-15     # Windows

# Create database
psql -U postgres -c "CREATE DATABASE IF NOT EXISTS postgres;"

# Create minimal schema
psql -U postgres -d postgres -f - <<'EOF'
CREATE TABLE IF NOT EXISTS public.products (
    ProductId SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Description TEXT,
    Price DECIMAL(18, 2) NOT NULL,
    StockQuantity INTEGER NOT NULL,
    CreatedDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ModifiedDate TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.producthistory (
    HistoryId SERIAL PRIMARY KEY,
    ProductId INTEGER NOT NULL,
    Action VARCHAR(10) NOT NULL,
    OldPrice DECIMAL(18, 2),
    NewPrice DECIMAL(18, 2),
    OldStock INTEGER,
    NewStock INTEGER,
    ActionDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ProductId) REFERENCES public.products(ProductId) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS public.productstats (
    StatId INTEGER PRIMARY KEY DEFAULT 1,
    TotalProducts INTEGER NOT NULL DEFAULT 0,
    AveragePrice DECIMAL(18, 2) NOT NULL DEFAULT 0,
    TotalStockValue DECIMAL(18, 2) NOT NULL DEFAULT 0,
    LowStockCount INTEGER NOT NULL DEFAULT 0,
    DiscontinuedCount INTEGER NOT NULL DEFAULT 0,
    LastUpdated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO public.productstats (StatId, TotalProducts, AveragePrice)
VALUES (1, 0, 0)
ON CONFLICT (StatId) DO NOTHING;

INSERT INTO public.products (Name, Description, Price, StockQuantity)
VALUES 
    ('Laptop', 'High-performance laptop', 999.99, 10),
    ('Mouse', 'Wireless gaming mouse', 49.99, 20),
    ('Keyboard', 'Mechanical keyboard', 129.99, 15);
EOF
```

### 3. Test Application
```bash
# Build
dotnet build

# Run
dotnet run

# Test operations
dotnet run -- list
dotnet run -- get 1
dotnet run -- add "Test Product" "Description" 79.99 10
```

---

## 📊 Migration Status

| Component | Status | Details |
|-----------|--------|--------|
| Packages | ✅ Complete | Npgsql 8.0.5 installed |
| Connection Strings | ✅ Complete | PostgreSQL format |
| ADO.NET Components | ✅ Complete | Npgsql* classes |
| SQL Syntax | ✅ Complete | PostgreSQL compatible |
| Database Scripts | ⚠️ Pending | Manual conversion needed |
| Testing | ⚠️ Pending | Awaiting database setup |
| Production Config | ⚠️ Pending | AWS Secrets Manager |

---

## 📖 Documentation Files

| File | Purpose | Read When |
|------|---------|----------|
| `MIGRATION_EXECUTIVE_SUMMARY.md` | High-level overview | Start here |
| `MIGRATION_VALIDATION_REPORT.md` | Detailed verification (13 sections) | Deep dive |
| `MIGRATION_CHECKLIST.md` | Task breakdown with code examples | Implementation |
| `POSTGRESQL_CONNECTION_TESTING_GUIDE.md` | Testing procedures | Testing phase |
| `QUICK_REFERENCE.md` | This file - Quick commands | Anytime |

---

## 🔧 Key Transformations

### Package References
```xml
<!-- BEFORE (SQL Server) -->
<PackageReference Include="Microsoft.Data.SqlClient" Version="5.0.0" />

<!-- AFTER (PostgreSQL) -->
<PackageReference Include="Npgsql" Version="8.0.5" />
```

### Connection Strings
```json
// BEFORE (SQL Server)
"Server=localhost;Database=MyDb;User Id=sa;Password=pass;"

// AFTER (PostgreSQL)
"Host=localhost;Database=postgres;Username=postgres;Password=postgres;"
```

### Using Statements
```csharp
// BEFORE (SQL Server)
using Microsoft.Data.SqlClient;
using SqlConnection = Microsoft.Data.SqlClient.SqlConnection;

// AFTER (PostgreSQL)
using Npgsql;
using NpgsqlConnection = Npgsql.NpgsqlConnection;
```

### ADO.NET Components
```csharp
// BEFORE (SQL Server)
var connection = new SqlConnection(connectionString);
var command = new SqlCommand(sql, connection);
SqlDataReader reader = await command.ExecuteReaderAsync();

// AFTER (PostgreSQL)
var connection = new NpgsqlConnection(connectionString);
var command = new NpgsqlCommand(sql, connection);
NpgsqlDataReader reader = await command.ExecuteReaderAsync();
```

### SQL Syntax
```sql
-- BEFORE (SQL Server)
SELECT GETDATE() AS CurrentDate;
INSERT INTO products (...) VALUES (...);
SELECT SCOPE_IDENTITY();

-- AFTER (PostgreSQL)
SELECT CURRENT_TIMESTAMP AS CurrentDate;
INSERT INTO public.products (...) VALUES (...)
RETURNING ProductId;
```

---

## 📝 SQL Syntax Cheat Sheet

| SQL Server | PostgreSQL | Usage |
|-----------|-----------|-------|
| `GETDATE()` | `CURRENT_TIMESTAMP` or `NOW()` | Current date/time |
| `SCOPE_IDENTITY()` | `RETURNING id` | Get inserted ID |
| `IDENTITY(1,1)` | `SERIAL` or `GENERATED ALWAYS AS IDENTITY` | Auto-increment |
| `NVARCHAR(n)` | `VARCHAR(n)` or `TEXT` | String types |
| `[dbo].[Table]` | `public.table` | Schema qualification |
| `TOP n` | `LIMIT n` | Limit rows |
| `ISNULL(x, y)` | `COALESCE(x, y)` | Null handling |
| `LEN(str)` | `LENGTH(str)` | String length |
| `CHARINDEX(a, b)` | `POSITION(a IN b)` | Find substring |
| `DATEADD(day, n, d)` | `d + INTERVAL 'n days'` | Date arithmetic |
| `DATEDIFF(day, a, b)` | `(b - a)::int` | Date difference |

---

## ⚡ Common Commands

### Build & Run
```bash
# Restore packages
dotnet restore

# Build
dotnet build

# Run (interactive)
dotnet run

# Run (CLI)
dotnet run -- list
dotnet run -- get <id>
dotnet run -- add <name> <desc> <price> <qty>
dotnet run -- update <id> <name> <desc> <price> <qty>
dotnet run -- delete <id>
dotnet run -- range <min> <max>
dotnet run -- lowstock <threshold>
```

### PostgreSQL Commands
```bash
# Connect to PostgreSQL
psql -U postgres -d postgres

# List databases
\l

# Connect to database
\c postgres

# List tables
\dt public.*

# Describe table
\d public.products

# List indexes
\di public.*

# Execute query
SELECT * FROM public.products;

# Exit
\q
```

### Database Management
```sql
-- Create database
CREATE DATABASE postgres;

-- Create schema
CREATE SCHEMA IF NOT EXISTS public;

-- Grant permissions
GRANT ALL ON DATABASE postgres TO postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres;

-- Vacuum (optimize)
VACUUM ANALYZE;

-- Check table size
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Check active connections
SELECT count(*) FROM pg_stat_activity WHERE datname = 'postgres';
```

---

## 🔍 Troubleshooting

### Connection Failed
```bash
# Check PostgreSQL is running
sudo systemctl status postgresql

# Check port
sudo netstat -plnt | grep 5432

# Check pg_hba.conf
sudo nano /etc/postgresql/15/main/pg_hba.conf
# Add: host    all    all    127.0.0.1/32    md5

# Restart PostgreSQL
sudo systemctl restart postgresql
```

### Authentication Failed
```bash
# Reset password
sudo -u postgres psql
ALTER USER postgres PASSWORD 'postgres';
\q

# Update appsettings.json with correct password
```

### Table Not Found
```sql
-- Check schema
\dt
\dt public.*

-- Create tables (see Quick Start section 2)
```

### Query Error
```sql
-- Enable verbose errors
\set VERBOSITY verbose

-- Check PostgreSQL log
sudo tail -f /var/log/postgresql/postgresql-15-main.log
```

---

## 📊 Performance Tips

### Connection Pooling
```json
// appsettings.json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Database=postgres;Username=postgres;Password=postgres;Pooling=true;MinPoolSize=5;MaxPoolSize=100;"
  }
}
```

### Indexes
```sql
-- Add indexes for frequently queried columns
CREATE INDEX idx_products_price ON public.products(price);
CREATE INDEX idx_products_stock ON public.products(stockquantity);
CREATE INDEX idx_products_created ON public.products(createddate);
```

### Query Analysis
```sql
-- Explain query plan
EXPLAIN ANALYZE SELECT * FROM public.products WHERE price > 100;

-- Check slow queries
SELECT query, total_time, calls
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;
```

---

## 🔐 Production Setup

### AWS Secrets Manager

**Option 1: Environment Variables (Recommended)**
```bash
# Set environment variables
export DB_HOST="your-rds-host.amazonaws.com"
export DB_USERNAME="postgres"
export DB_PASSWORD="$(aws secretsmanager get-secret-value --secret-id <ARN> --query SecretString --output text | jq -r .password)"
export DB_NAME="postgres"
```

**Option 2: Direct SDK Integration**
```xml
<!-- Add to .csproj -->
<PackageReference Include="AWSSDK.SecretsManager" Version="3.7.0" />
```

```csharp
// Add to ProductRepository.cs
using Amazon.SecretsManager;
using Amazon.SecretsManager.Model;

private async Task<string> GetSecretConnectionString()
{
    var secretArn = "arn:aws:secretsmanager:us-east-1:789616364195:secret:...-t0337O";
    using var client = new AmazonSecretsManagerClient(Amazon.RegionEndpoint.USEast1);
    var request = new GetSecretValueRequest { SecretId = secretArn };
    var response = await client.GetSecretValueAsync(request);
    var secret = JsonSerializer.Deserialize<Dictionary<string, string>>(response.SecretString);
    return $"Host={secret["host"]};Database=postgres;Username={secret["username"]};Password={secret["password"]};";
}
```

---

## ✅ Verification Checklist

### Code Level (Complete)
- [x] Npgsql package installed (version 8.0.5)
- [x] SQL Server packages removed
- [x] Connection strings use PostgreSQL format
- [x] Target database name: `postgres`
- [x] `NpgsqlConnection` used throughout
- [x] `NpgsqlCommand` used throughout
- [x] `NpgsqlDataReader` used throughout
- [x] `GETDATE()` replaced with `CURRENT_TIMESTAMP`
- [x] `SCOPE_IDENTITY()` replaced with `RETURNING`
- [x] Schema qualification: `public.tablename`
- [x] Window functions verified
- [x] CTEs verified
- [x] Transactions verified

### Database Level (Pending)
- [ ] PostgreSQL database created
- [ ] Tables created in public schema
- [ ] Sample data inserted
- [ ] Indexes created
- [ ] Constraints verified

### Application Level (Pending)
- [ ] Application builds successfully
- [ ] Application runs without errors
- [ ] CRUD operations work
- [ ] Complex queries work
- [ ] Transactions work
- [ ] Performance acceptable

### Production Level (Pending)
- [ ] AWS Secrets Manager configured
- [ ] Production connection string tested
- [ ] Deployed to test environment
- [ ] Deployed to production

---

## 📞 Support Resources

### Documentation
- **PostgreSQL**: https://www.postgresql.org/docs/
- **Npgsql**: https://www.npgsql.org/doc/
- **.NET Data Access**: https://docs.microsoft.com/en-us/dotnet/framework/data/adonet/
- **AWS DMS**: https://docs.aws.amazon.com/dms/

### Project Files
- `MIGRATION_EXECUTIVE_SUMMARY.md` - Overview and status
- `MIGRATION_VALIDATION_REPORT.md` - Detailed verification (13 sections)
- `MIGRATION_CHECKLIST.md` - Task breakdown with examples
- `POSTGRESQL_CONNECTION_TESTING_GUIDE.md` - Testing procedures

### AWS Configuration
- **Secret ARN**: `arn:aws:secretsmanager:us-east-1:789616364195:secret:...-t0337O`
- **Region**: `us-east-1`
- **Target Database**: `postgres`

---

## 🚀 Next Steps

1. **Now**: Setup PostgreSQL database (see Quick Start section 2)
2. **Next**: Test application (see Quick Start section 3)
3. **Then**: Configure production (see Production Setup section)
4. **Finally**: Deploy and monitor

**Estimated Time to Production:** 7-13 hours

---

**Last Updated:** 2024  
**Migration Status:** ✅ Code Complete, ⚠️ Deployment Pending  
**Quick Reference Version:** 1.0
