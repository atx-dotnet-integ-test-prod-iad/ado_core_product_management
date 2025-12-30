# Security Guidelines for PostgreSQL Migration

## ⚠️ CRITICAL SECURITY ISSUES TO ADDRESS

### 1. Connection String Security

**Current Issue**: The `appsettings.json` file contains hardcoded credentials:
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres"
  }
}
```

**REQUIRED ACTIONS BEFORE PRODUCTION DEPLOYMENT**:

#### Option A: Use Environment Variables (Recommended)
```bash
# Set environment variables
export ConnectionStrings__DevConnection="Host=your-host;Port=5432;Database=ProductManagement;Username=your-user;Password=your-secure-password"
```

Update Program.cs to read from environment:
```csharp
var configuration = new ConfigurationBuilder()
    .AddJsonFile("appsettings.json", optional: false)
    .AddEnvironmentVariables()  // This allows environment variables to override
    .Build();
```

#### Option B: Use AWS Secrets Manager (Production)
```bash
# Store secret in AWS Secrets Manager
aws secretsmanager create-secret \
    --name /prod/postgresql/connection-string \
    --secret-string "Host=prod-db.amazonaws.com;Port=5432;Database=ProductManagement;Username=app_user;Password=SECURE_PASSWORD_HERE"
```

Add AWS Secrets Manager SDK:
```bash
dotnet add package AWSSDK.SecretsManager
```

#### Option C: Use User Secrets (Development Only)
```bash
# Initialize user secrets
dotnet user-secrets init

# Add connection string
dotnet user-secrets set "ConnectionStrings:DevConnection" "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_LOCAL_PASSWORD"
```

### 2. Package Vulnerabilities

**Status**: ✅ RESOLVED - Npgsql upgraded from 8.0.0 to 8.0.5

The vulnerability (GHSA-x9vc-6hfv-hg8c) in Npgsql 8.0.0 has been addressed by upgrading to version 8.0.5.

**Ongoing Monitoring**:
```bash
# Regularly check for vulnerabilities
dotnet list package --vulnerable

# Keep packages updated
dotnet add package Npgsql
```

### 3. Database User Permissions

**REQUIRED**: Create a dedicated application user with minimal privileges:

```sql
-- Create application-specific user (run as PostgreSQL admin)
CREATE USER app_user WITH PASSWORD 'SECURE_PASSWORD_HERE';

-- Grant only required permissions
GRANT CONNECT ON DATABASE ProductManagement TO app_user;
GRANT USAGE ON SCHEMA productmanagement_dbo TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA productmanagement_dbo TO app_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA productmanagement_dbo TO app_user;

-- DO NOT use the 'postgres' superuser account for application connections
```

### 4. Network Security

**PostgreSQL Configuration** (`postgresql.conf`):
```ini
# Only allow connections from application servers
listen_addresses = 'localhost,10.0.1.5'  # Specific IPs only

# Require SSL/TLS for connections
ssl = on
ssl_cert_file = '/path/to/server.crt'
ssl_key_file = '/path/to/server.key'
```

**pg_hba.conf** (Host-Based Authentication):
```
# TYPE  DATABASE        USER            ADDRESS                 METHOD
# Require SSL and password authentication
hostssl ProductManagement app_user      10.0.1.0/24            scram-sha-256
```

**Connection String Update**:
```
Host=your-host;Port=5432;Database=ProductManagement;Username=app_user;Password=secure-password;SSL Mode=Require;Trust Server Certificate=false
```

### 5. SQL Injection Protection

**Status**: ✅ IMPLEMENTED - All queries use parameterized statements

All database operations use `NpgsqlParameter` to prevent SQL injection:
```csharp
command.Parameters.AddWithValue("@ProductId", productId);
```

**Verify**: No string concatenation is used for SQL query construction.

### 6. Error Handling and Information Disclosure

**Review Required**: Ensure error messages don't expose sensitive information:

```csharp
// GOOD: Generic error message to users
catch (Exception ex)
{
    Console.WriteLine("An error occurred while processing your request.");
    // Log detailed error securely (not shown to users)
    logger.LogError(ex, "Database operation failed for ProductId: {ProductId}", productId);
}

// BAD: Exposing internal details
catch (Exception ex)
{
    Console.WriteLine($"Error: {ex.Message}\nStack: {ex.StackTrace}");  // DON'T DO THIS
}
```

## Pre-Production Checklist

- [ ] Remove hardcoded credentials from `appsettings.json`
- [ ] Implement secure credential management (Environment Variables, AWS Secrets Manager, or Azure Key Vault)
- [ ] Create dedicated database user with minimal privileges
- [ ] Remove 'postgres' superuser from connection strings
- [ ] Enable SSL/TLS for database connections
- [ ] Configure `pg_hba.conf` to restrict connections by IP
- [ ] Update connection string to use `SSL Mode=Require`
- [ ] Verify all packages are up-to-date and vulnerability-free
- [ ] Review error handling to prevent information disclosure
- [ ] Set up database connection pooling limits
- [ ] Implement rate limiting for API endpoints (if applicable)
- [ ] Enable database audit logging
- [ ] Regular security updates and monitoring

## References

- [PostgreSQL Security Best Practices](https://www.postgresql.org/docs/current/security.html)
- [Npgsql Security](https://www.npgsql.org/doc/security.html)
- [ASP.NET Core Security](https://docs.microsoft.com/en-us/aspnet/core/security/)
- [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/)
- [Azure Key Vault](https://azure.microsoft.com/en-us/services/key-vault/)
