# AdoCore PostgreSQL Migration - Deployment Guide

## Overview

This document provides deployment guidance for the AdoCore application after migration from SQL Server to PostgreSQL.

## ⚠️ CRITICAL: Pre-Deployment Checklist

Before deploying to any non-development environment, ensure the following are addressed:

### 1. Security Requirements

- [ ] **Remove hardcoded credentials** from `appsettings.json`
- [ ] **Implement secure credential management** (see Security Setup section below)
- [ ] **Create dedicated database user** with minimal required permissions
- [ ] **Enable SSL/TLS** for database connections (production only)
- [ ] **Review and update** pg_hba.conf for proper authentication
- [ ] **Implement connection pooling** for better resource management
- [ ] **Enable database audit logging** for compliance

### 2. Database Validation

- [ ] **PostgreSQL database instance** is running and accessible
- [ ] **Schema migration script** has been executed successfully
- [ ] **All tables and indexes** are created correctly
- [ ] **Sample data** is loaded (or production data migrated)
- [ ] **Triggers** are functioning correctly
- [ ] **Foreign key constraints** are enforced

### 3. Application Validation

- [ ] **Application builds** without errors (`dotnet build AdoCore.sln`)
- [ ] **Connection string** is configured correctly
- [ ] **All CRUD operations** have been tested
- [ ] **Transaction rollback** scenarios have been tested
- [ ] **Error handling** is working correctly
- [ ] **Logging** is configured appropriately

### 4. Functional Testing

Given that all 7 SQL statements returned ERROR from the equivalency validation tool, **comprehensive functional testing is MANDATORY**:

- [ ] Test GetAllProductsAsync - verify complete result set
- [ ] Test GetProductByIdAsync - verify correct product returned
- [ ] Test InsertProductAsync - verify INSERT with RETURNING works
- [ ] Test UpdateProductAsync - verify UPDATE within transaction
- [ ] Test DeleteProductAsync - verify DELETE within transaction
- [ ] Test GetProductsByPriceRangeAsync - verify price filtering
- [ ] Test GetLowStockProductsAsync - verify stock comparison logic
- [ ] Test transaction atomicity - verify rollback on errors
- [ ] Test NULL handling - verify nullable columns work correctly
- [ ] Compare results with SQL Server baseline (if available)

---

## Security Setup

### Option 1: Environment Variables (Recommended for Most Deployments)

#### Step 1: Create Dedicated Database User

```sql
-- Connect as postgres superuser
psql -U postgres -d productmanagement

-- Create dedicated application user
CREATE USER adocore_app WITH PASSWORD 'your_strong_password_here';

-- Grant minimal required permissions
GRANT CONNECT ON DATABASE productmanagement TO adocore_app;
GRANT USAGE ON SCHEMA productmanagement_dbo TO adocore_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA productmanagement_dbo TO adocore_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA productmanagement_dbo TO adocore_app;

-- For production, consider read-only users for reporting
CREATE USER adocore_readonly WITH PASSWORD 'another_strong_password';
GRANT CONNECT ON DATABASE productmanagement TO adocore_readonly;
GRANT USAGE ON SCHEMA productmanagement_dbo TO adocore_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA productmanagement_dbo TO adocore_readonly;
```

#### Step 2: Set Environment Variables

**Linux/Mac:**
```bash
export DB_HOST="localhost"
export DB_PORT="5432"
export DB_NAME="productmanagement"
export DB_USER="adocore_app"
export DB_PASSWORD="your_strong_password_here"
```

**Windows (PowerShell):**
```powershell
$env:DB_HOST="localhost"
$env:DB_PORT="5432"
$env:DB_NAME="productmanagement"
$env:DB_USER="adocore_app"
$env:DB_PASSWORD="your_strong_password_here"
```

**Docker:**
```yaml
version: '3.8'
services:
  adocore:
    image: adocore:latest
    environment:
      - DB_HOST=postgres
      - DB_PORT=5432
      - DB_NAME=productmanagement
      - DB_USER=adocore_app
      - DB_PASSWORD=${DB_PASSWORD}  # Read from .env file
    depends_on:
      - postgres
  
  postgres:
    image: postgres:14
    environment:
      - POSTGRES_DB=productmanagement
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./Database/Scripts/01_InitialSetup_PostgreSQL.sql:/docker-entrypoint-initdb.d/init.sql

volumes:
  postgres_data:
```

#### Step 3: Update Program.cs to Read Environment Variables

```csharp
// In Program.cs, modify ConfigureServices method
private static void ConfigureServices(IServiceCollection services, IConfiguration configuration)
{
    // Build connection string from environment variables in production
    string connectionString;
    
    if (configuration["Environment"] == "Production")
    {
        var host = Environment.GetEnvironmentVariable("DB_HOST") ?? "localhost";
        var port = Environment.GetEnvironmentVariable("DB_PORT") ?? "5432";
        var database = Environment.GetEnvironmentVariable("DB_NAME") ?? "productmanagement";
        var username = Environment.GetEnvironmentVariable("DB_USER") ?? "postgres";
        var password = Environment.GetEnvironmentVariable("DB_PASSWORD");
        
        if (string.IsNullOrEmpty(password))
        {
            throw new InvalidOperationException("DB_PASSWORD environment variable is required in production");
        }
        
        connectionString = $"Host={host};Port={port};Database={database};" +
                          $"Username={username};Password={password};" +
                          "SSL Mode=Require;Include Error Detail=true";
    }
    else
    {
        // Use configured connection string for development
        connectionString = configuration.GetConnectionString("DevConnection");
    }
    
    // Store in configuration for use by repositories
    configuration["ConnectionStrings:DefaultConnection"] = connectionString;
    
    services.AddSingleton(configuration);
    services.AddScoped<ProductRepository>();
    services.AddScoped<ProductService>();
    services.AddScoped<CommandLineInterface>();
    services.AddScoped<InteractiveMenu>();
}
```

### Option 2: Azure Key Vault (For Azure Deployments)

#### Step 1: Install NuGet Package

```bash
dotnet add package Azure.Identity
dotnet add package Azure.Security.KeyVault.Secrets
```

#### Step 2: Store Secrets in Key Vault

```bash
# Using Azure CLI
az keyvault secret set --vault-name "your-keyvault" --name "DB-PASSWORD" --value "your_password"
az keyvault secret set --vault-name "your-keyvault" --name "DB-CONNECTION-STRING" --value "Host=...;Password=..."
```

#### Step 3: Retrieve Secrets in Code

```csharp
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

var keyVaultName = Environment.GetEnvironmentVariable("KEY_VAULT_NAME");
var kvUri = $"https://{keyVaultName}.vault.azure.net";

var client = new SecretClient(new Uri(kvUri), new DefaultAzureCredential());
KeyVaultSecret secret = await client.GetSecretAsync("DB-CONNECTION-STRING");
string connectionString = secret.Value;
```

### Option 3: AWS Secrets Manager (For AWS Deployments)

#### Step 1: Install NuGet Package

```bash
dotnet add package AWSSDK.SecretsManager
```

#### Step 2: Store Secret in AWS Secrets Manager

```bash
aws secretsmanager create-secret \
    --name adocore/db/connection \
    --secret-string '{"host":"localhost","port":"5432","database":"productmanagement","username":"adocore_app","password":"your_password"}'
```

#### Step 3: Retrieve Secret in Code

```csharp
using Amazon.SecretsManager;
using Amazon.SecretsManager.Model;
using System.Text.Json;

var client = new AmazonSecretsManagerClient();
var request = new GetSecretValueRequest
{
    SecretId = "adocore/db/connection"
};

var response = await client.GetSecretValueAsync(request);
var secret = JsonSerializer.Deserialize<DatabaseCredentials>(response.SecretString);

string connectionString = $"Host={secret.Host};Port={secret.Port};Database={secret.Database};" +
                         $"Username={secret.Username};Password={secret.Password};" +
                         "SSL Mode=Require;Include Error Detail=true";
```

---

## Deployment Steps

### Step 1: Prepare Database

1. **Install PostgreSQL** (version 12 or higher)
2. **Create database**: `CREATE DATABASE productmanagement;`
3. **Run schema migration**: `psql -U postgres -d productmanagement -f Database/Scripts/01_InitialSetup_PostgreSQL.sql`
4. **Verify setup**: Check that all tables, indexes, and triggers are created

### Step 2: Configure Application

1. **Remove hardcoded credentials** from appsettings.json
2. **Implement secure credential management** (choose one option above)
3. **Update connection string configuration** in code
4. **Set environment variables** or configure secret management service

### Step 3: Build and Test

```bash
# Clean build
dotnet clean
dotnet restore
dotnet build AdoCore.sln

# Verify build succeeded with 0 errors
# (10 nullable reference warnings are acceptable)

# Run the application
dotnet run --project AdoCore.csproj
```

### Step 4: Functional Testing (MANDATORY)

Because the SQL Equivalency tool could not validate any of the 7 SQL statements (all returned ERROR), comprehensive manual functional testing is required:

```bash
# Test each CRUD operation through the application
dotnet run --project AdoCore.csproj

# Test scenarios:
# 1. List all products
# 2. Get product by ID (test with valid and invalid IDs)
# 3. Insert new product (verify RETURNING clause works)
# 4. Update product (verify transaction commits)
# 5. Delete product (verify transaction commits)
# 6. Get products by price range (test boundary conditions)
# 7. Get low stock products (verify comparison logic)
# 8. Test transaction rollback (simulate errors)
```

### Step 5: Performance Testing

```bash
# Monitor query performance
# Compare with SQL Server baseline if available
# Check for slow queries in PostgreSQL logs
# Verify indexes are being used (EXPLAIN ANALYZE)
```

### Step 6: Deploy to Target Environment

**For Docker:**
```bash
# Build image
docker build -t adocore:latest .

# Run with environment variables
docker run -d \
  -e DB_HOST=postgres \
  -e DB_PORT=5432 \
  -e DB_NAME=productmanagement \
  -e DB_USER=adocore_app \
  -e DB_PASSWORD=${DB_PASSWORD} \
  --name adocore \
  adocore:latest
```

**For Systemd Service:**
```ini
# /etc/systemd/system/adocore.service
[Unit]
Description=AdoCore Application
After=network.target postgresql.service

[Service]
Type=simple
User=adocore
WorkingDirectory=/opt/adocore
ExecStart=/usr/bin/dotnet /opt/adocore/AdoCore.dll
Restart=on-failure
RestartSec=10
KillSignal=SIGINT
Environment="DB_HOST=localhost"
Environment="DB_PORT=5432"
Environment="DB_NAME=productmanagement"
Environment="DB_USER=adocore_app"
EnvironmentFile=/etc/adocore/secrets.env

[Install]
WantedBy=multi-user.target
```

---

## Monitoring and Maintenance

### Database Monitoring

```sql
-- Monitor active connections
SELECT count(*) FROM pg_stat_activity WHERE datname = 'productmanagement';

-- Check query performance
SELECT query, mean_exec_time, calls 
FROM pg_stat_statements 
ORDER BY mean_exec_time DESC 
LIMIT 10;

-- Monitor table sizes
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename))
FROM pg_tables 
WHERE schemaname = 'productmanagement_dbo'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### Application Logging

Implement structured logging for:
- Database connection events
- Query execution times
- Transaction success/failure
- Error conditions

### Backup Strategy

```bash
# Daily backup
pg_dump -U postgres -d productmanagement -F c -f backup_$(date +%Y%m%d).dump

# Restore if needed
pg_restore -U postgres -d productmanagement backup_20260102.dump
```

---

## Rollback Plan

If issues are discovered post-deployment:

1. **Stop the application**
2. **Restore SQL Server connection** (appsettings.json.backup exists)
3. **Switch back to SQL Server database**
4. **Investigate PostgreSQL issues** in non-production environment
5. **Re-deploy after fixes** are validated

---

## Known Issues and Limitations

### SQL Equivalency Validation

All 7 SQL statements returned ERROR status from the equivalency validation tool:
- 4 statements: Tool returned UNKNOWN (marked as ERROR per transformation definition)
- 3 statements: Multi-statement transactions cannot be validated by the tool

**Impact:** Functional testing is MANDATORY to verify correctness.

**Mitigation:** Comprehensive test suite covering all operations and edge cases.

### Transaction Management

Transaction management was redesigned from SQL-level (BEGIN TRANSACTION/COMMIT in SQL) to application-level (C# using NpgsqlTransaction):

**Testing Required:**
- Verify transaction commits work correctly
- Verify rollback works on errors
- Verify atomicity is maintained
- Test concurrent transaction scenarios

### RETURNING Clause

The INSERT statement in `InsertProductAsync` uses PostgreSQL's RETURNING clause to get the new product ID. This replaces SQL Server's SCOPE_IDENTITY():

**SQL Server:** `SELECT SCOPE_IDENTITY()`
**PostgreSQL:** `RETURNING productid, name, description, price, stockquantity, createddate`

**Testing Required:** Verify the application correctly captures and uses the returned product ID.

---

## Support and Troubleshooting

### Common Issues

**Issue:** "Connection refused" error
**Solution:** Verify PostgreSQL is running and accessible on the configured host/port

**Issue:** "Authentication failed" error
**Solution:** Verify username/password are correct, check pg_hba.conf authentication method

**Issue:** "Schema not found" error
**Solution:** Verify schema migration script ran successfully, check schema name in queries

**Issue:** "Permission denied" error
**Solution:** Verify database user has appropriate GRANT permissions

### Debug Checklist

- [ ] PostgreSQL service is running
- [ ] Database and schema exist
- [ ] Connection string is correctly formatted
- [ ] Environment variables are set (if used)
- [ ] Database user has appropriate permissions
- [ ] SSL/TLS certificates are valid (if required)
- [ ] Firewall rules allow connections
- [ ] Application logs show detailed error messages

### Migration Documentation

For detailed information about the migration:
- **final_migration_report.md** - Complete migration summary
- **sql_equivalency_validation_report.json** - SQL statement equivalency status
- **dms_conversion_log.txt** - DMS tool conversion log
- **equivalency_validation_log.txt** - Equivalency validation log
- **Database/README.md** - Database setup instructions

---

## Conclusion

This migration has successfully converted all code from SQL Server to PostgreSQL:
- ✅ All 7 SQL statements processed through DMS tool
- ✅ All dependencies updated to Npgsql
- ✅ All ADO.NET classes converted
- ✅ Application builds successfully
- ✅ Schema migration script created

**Remaining Steps:**
1. Set up PostgreSQL database instance
2. Implement secure credential management
3. Run comprehensive functional tests
4. Deploy to target environment
5. Monitor and optimize performance

**Critical:** Due to equivalency validation limitations, functional testing is mandatory before production deployment.
