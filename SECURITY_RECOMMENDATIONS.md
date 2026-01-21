# Security Recommendations for PostgreSQL Migration

## Overview
This document provides security recommendations for the AdoCore application after migration from Microsoft SQL Server to PostgreSQL. These recommendations should be implemented before deploying to production.

## 1. Connection String Security

### Current State
The application currently uses hardcoded credentials in `appsettings.json`:
- Username: `postgres`
- Password: `postgres`
- No SSL/TLS encryption enabled

### Recommendations

#### 1.1 Remove Hardcoded Credentials
**Priority: CRITICAL**

Replace hardcoded credentials with secure credential storage:

**Option A: .NET User Secrets (Development)**
```bash
# Initialize user secrets
dotnet user-secrets init

# Set connection string
dotnet user-secrets set "ConnectionStrings:DevConnection" "Host=localhost;Port=5432;Database=productmanagement;Username=postgres;Password=YOUR_SECURE_PASSWORD;Pooling=true;MinPoolSize=1;MaxPoolSize=20;Timeout=30;SslMode=Require"
```

**Option B: Environment Variables**
```bash
# Set environment variable
export ConnectionStrings__DevConnection="Host=localhost;Port=5432;Database=productmanagement;Username=postgres;Password=YOUR_SECURE_PASSWORD;Pooling=true;MinPoolSize=1;MaxPoolSize=20;Timeout=30;SslMode=Require"
```

**Option C: Azure Key Vault (Production)**
```csharp
// Add to Program.cs or Startup.cs
builder.Configuration.AddAzureKeyVault(
    new Uri($"https://{keyVaultName}.vault.azure.net/"),
    new DefaultAzureCredential());
```

**Option D: AWS Secrets Manager (Production)**
```csharp
// Add to Program.cs or Startup.cs
builder.Configuration.AddSecretsManager();
```

#### 1.2 Enable SSL/TLS Encryption
**Priority: CRITICAL**

Add SSL/TLS parameters to connection strings:
```
SslMode=Require;Trust Server Certificate=false
```

Full connection string example:
```
Host=localhost;Port=5432;Database=productmanagement;Username=postgres;Password=YOUR_SECURE_PASSWORD;Pooling=true;MinPoolSize=1;MaxPoolSize=20;Timeout=30;SslMode=Require;Trust Server Certificate=false
```

SSL Mode options:
- `Disable`: No SSL (NOT RECOMMENDED for production)
- `Prefer`: SSL if available (NOT RECOMMENDED for production)
- `Require`: Always use SSL (RECOMMENDED minimum)
- `VerifyCA`: SSL with CA verification (RECOMMENDED)
- `VerifyFull`: SSL with full certificate validation (MOST SECURE)

#### 1.3 Use Dedicated Database User
**Priority: HIGH**

Create a dedicated application user instead of using the `postgres` superuser:

```sql
-- Create application-specific user
CREATE USER adocore_app WITH PASSWORD 'YOUR_SECURE_PASSWORD';

-- Grant only necessary permissions
GRANT CONNECT ON DATABASE productmanagement TO adocore_app;
GRANT USAGE ON SCHEMA productmanagement_dbo TO adocore_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA productmanagement_dbo TO adocore_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA productmanagement_dbo TO adocore_app;

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA productmanagement_dbo GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO adocore_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA productmanagement_dbo GRANT USAGE, SELECT ON SEQUENCES TO adocore_app;
```

## 2. Database Security Configuration

### 2.1 PostgreSQL Server Configuration
**Priority: HIGH**

Update `postgresql.conf`:
```conf
# Enable SSL
ssl = on
ssl_cert_file = '/path/to/server.crt'
ssl_key_file = '/path/to/server.key'
ssl_ca_file = '/path/to/ca.crt'

# Require SSL for all connections
ssl_prefer_server_ciphers = on
ssl_min_protocol_version = 'TLSv1.2'

# Authentication
password_encryption = scram-sha-256
```

Update `pg_hba.conf`:
```conf
# Require SSL for all TCP/IP connections
hostssl all all 0.0.0.0/0 scram-sha-256
```

### 2.2 Connection Pooling Security
**Priority: MEDIUM**

Current connection pool settings are appropriate:
- `MinPoolSize=1`: Reduces idle connections
- `MaxPoolSize=20`: Limits maximum connections
- `Timeout=30`: Prevents hanging connections

Consider adding:
- `Connection Lifetime=300`: Recycle connections every 5 minutes
- `Connection Idle Lifetime=60`: Close idle connections after 60 seconds

## 3. Application-Level Security

### 3.1 SQL Injection Prevention
**Priority: HIGH**

**Current State: GOOD** - The application uses parameterized queries throughout, which provides protection against SQL injection.

**Verification**: All SQL statements in `ProductRepository.cs` use `NpgsqlParameter` objects.

**Maintain**: Continue using parameterized queries for all database operations. Never concatenate user input into SQL strings.

### 3.2 Input Validation
**Priority: HIGH**

Add validation for all user inputs before database operations:

```csharp
public async Task<int> InsertProductAsync(Product product)
{
    // Validate inputs
    if (string.IsNullOrWhiteSpace(product.Name))
        throw new ArgumentException("Product name cannot be empty", nameof(product.Name));
    
    if (product.Name.Length > 255)
        throw new ArgumentException("Product name cannot exceed 255 characters", nameof(product.Name));
    
    if (product.Price < 0)
        throw new ArgumentException("Product price cannot be negative", nameof(product.Price));
    
    // Proceed with database operation
    // ...
}
```

### 3.3 Error Handling and Information Disclosure
**Priority: MEDIUM**

Avoid exposing detailed database errors to end users:

```csharp
try
{
    // Database operation
}
catch (NpgsqlException ex)
{
    // Log detailed error for troubleshooting
    _logger.LogError(ex, "Database error occurred during operation");
    
    // Return generic error to user
    throw new ApplicationException("An error occurred while processing your request. Please try again later.");
}
```

## 4. Monitoring and Auditing

### 4.1 Enable PostgreSQL Logging
**Priority: MEDIUM**

Update `postgresql.conf`:
```conf
# Log connections
log_connections = on
log_disconnections = on

# Log statements
log_statement = 'mod'  # Log all data-modifying statements
log_duration = on
log_min_duration_statement = 1000  # Log queries taking > 1 second

# Log errors
log_error_verbosity = default
```

### 4.2 Application Logging
**Priority: MEDIUM**

Add logging for security-relevant events:
- Failed authentication attempts
- Unauthorized access attempts
- Data modification operations
- Unusual query patterns

## 5. Package Security

### 5.1 Npgsql Version ✅ RESOLVED
**Priority: CRITICAL**

**Status: FIXED** - Npgsql has been upgraded from 8.0.0 to 8.0.5, resolving the known high-severity vulnerability (CVE-2024-XXXXX, GHSA-x9vc-6hfv-hg8c).

**Verification**: No NU1903 warnings in build output.

**Maintain**: Keep Npgsql and all dependencies up to date:
```bash
# Check for updates regularly
dotnet list package --outdated

# Update packages
dotnet add package Npgsql
```

## 6. Network Security

### 6.1 Firewall Configuration
**Priority: HIGH**

- Restrict PostgreSQL port (5432) access to application servers only
- Use network segmentation to isolate database server
- Consider using a bastion host or VPN for administrative access

### 6.2 Connection String in Production
**Priority: CRITICAL**

For production deployments:
- Use private network endpoints (not public IPs)
- Enable connection encryption (SSL/TLS)
- Use managed database services with built-in security (AWS RDS, Azure Database for PostgreSQL)

Example production connection string:
```
Host=db.internal.company.com;Port=5432;Database=productmanagement;Username=adocore_app;Password=USE_SECRETS_MANAGER;Pooling=true;MinPoolSize=1;MaxPoolSize=20;Timeout=30;SslMode=VerifyFull;Trust Server Certificate=false;Connection Lifetime=300
```

## 7. Immediate Action Items

### Before Production Deployment (CRITICAL)
1. ✅ **COMPLETED**: Upgrade Npgsql to 8.0.5 or later
2. ⚠️ **REQUIRED**: Remove hardcoded credentials from appsettings.json
3. ⚠️ **REQUIRED**: Implement secure credential storage (User Secrets, Key Vault, or Secrets Manager)
4. ⚠️ **REQUIRED**: Enable SSL/TLS for all database connections
5. ⚠️ **REQUIRED**: Create dedicated database user with minimal permissions
6. ⚠️ **REQUIRED**: Configure PostgreSQL to require SSL connections

### Post-Deployment (HIGH PRIORITY)
1. ⚠️ **RECOMMENDED**: Implement comprehensive input validation
2. ⚠️ **RECOMMENDED**: Configure PostgreSQL logging and monitoring
3. ⚠️ **RECOMMENDED**: Set up network firewall rules
4. ⚠️ **RECOMMENDED**: Implement application-level audit logging

### Ongoing (MEDIUM PRIORITY)
1. ⚠️ **RECOMMENDED**: Regular security audits
2. ⚠️ **RECOMMENDED**: Dependency updates and vulnerability scanning
3. ⚠️ **RECOMMENDED**: Review and update access controls
4. ⚠️ **RECOMMENDED**: Monitor database performance and connection patterns

## 8. References

- [Npgsql Security Best Practices](https://www.npgsql.org/doc/security.html)
- [PostgreSQL Security Documentation](https://www.postgresql.org/docs/current/security.html)
- [OWASP SQL Injection Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html)
- [.NET Secret Management](https://docs.microsoft.com/en-us/aspnet/core/security/app-secrets)
- [Azure Key Vault](https://docs.microsoft.com/en-us/azure/key-vault/)
- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/)

## 9. Security Checklist

Use this checklist before production deployment:

- [ ] Npgsql upgraded to 8.0.5 or later (✅ COMPLETED)
- [ ] Hardcoded credentials removed from appsettings.json
- [ ] Secure credential storage implemented
- [ ] SSL/TLS enabled for database connections
- [ ] Dedicated database user created with minimal permissions
- [ ] PostgreSQL configured to require SSL connections
- [ ] Input validation implemented for all user inputs
- [ ] Error handling prevents information disclosure
- [ ] Database logging enabled
- [ ] Application logging configured for security events
- [ ] Network firewall rules configured
- [ ] Connection pooling settings optimized
- [ ] Security testing completed
- [ ] Monitoring and alerting configured

---

**Document Version**: 1.0  
**Last Updated**: January 21, 2026  
**Next Review**: Before production deployment
