# Security Recommendations for Production Deployment

## Critical: Connection String Security

### Current State
The `appsettings.json` file contains hardcoded PostgreSQL credentials:
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=productmanagement;Username=postgres;Password=postgres;Pooling=true",
    "ProdConnection": "Host=localhost;Port=5432;Database=productmanagement;Username=postgres;Password=postgres;Pooling=true"
  }
}
```

**⚠️ WARNING**: These credentials are suitable for development/testing ONLY. Never deploy to production with hardcoded credentials.

## Production Security Requirements

### 1. Externalize Database Credentials

#### Option A: Environment Variables (Recommended for most scenarios)
```csharp
// In Program.cs or Startup.cs
var connectionString = $"Host={Environment.GetEnvironmentVariable("DB_HOST")};" +
                      $"Port={Environment.GetEnvironmentVariable("DB_PORT")};" +
                      $"Database={Environment.GetEnvironmentVariable("DB_NAME")};" +
                      $"Username={Environment.GetEnvironmentVariable("DB_USERNAME")};" +
                      $"Password={Environment.GetEnvironmentVariable("DB_PASSWORD")};" +
                      $"Pooling=true";
```

Set environment variables:
```bash
export DB_HOST=your-postgres-host
export DB_PORT=5432
export DB_NAME=productmanagement
export DB_USERNAME=your-username
export DB_PASSWORD=your-secure-password
```

#### Option B: Azure Key Vault (Recommended for Azure deployments)
```csharp
// Add package: Azure.Security.KeyVault.Secrets
// Add package: Azure.Identity

var keyVaultUrl = Environment.GetEnvironmentVariable("KEY_VAULT_URL");
var client = new SecretClient(new Uri(keyVaultUrl), new DefaultAzureCredential());

var dbHost = client.GetSecret("DB-HOST").Value.Value;
var dbPassword = client.GetSecret("DB-PASSWORD").Value.Value;
// ... build connection string from Key Vault secrets
```

#### Option C: AWS Secrets Manager (Recommended for AWS deployments)
```csharp
// Add package: AWSSDK.SecretsManager

var client = new AmazonSecretsManagerClient();
var request = new GetSecretValueRequest
{
    SecretId = "prod/postgres/credentials"
};
var response = await client.GetSecretValueAsync(request);
var secrets = JsonSerializer.Deserialize<Dictionary<string, string>>(response.SecretString);
// ... build connection string from Secrets Manager
```

#### Option D: User Secrets (Development only)
```bash
dotnet user-secrets init
dotnet user-secrets set "ConnectionStrings:DevConnection" "Host=localhost;Port=5432;Database=productmanagement;Username=devuser;Password=devpassword;Pooling=true"
```

### 2. Connection String Encryption

For appsettings.json in production (if not using environment variables):
```bash
# Encrypt connection strings section
aspnet_regiis -pef "connectionStrings" "C:\path\to\app" -prov "DataProtectionConfigurationProvider"
```

### 3. Implement Principle of Least Privilege

Create database users with minimal required permissions:

```sql
-- Create application user with limited permissions
CREATE USER app_user WITH PASSWORD 'strong_password_here';

-- Grant only necessary permissions
GRANT CONNECT ON DATABASE productmanagement TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE Products TO app_user;
GRANT SELECT, INSERT ON TABLE ProductHistory TO app_user;
GRANT SELECT ON TABLE ProductStats TO app_user;

-- Grant sequence permissions for RETURNING clauses
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;
```

### 4. Enable SSL/TLS for Database Connections

Update connection string for production:
```
Host=your-host;Port=5432;Database=productmanagement;Username=app_user;Password=env_password;SslMode=Require;Trust Server Certificate=false;Pooling=true
```

SSL Modes:
- `Disable` - No SSL (development only)
- `Prefer` - Use SSL if available
- `Require` - Always use SSL (recommended for production)
- `VerifyCA` - Use SSL and verify certificate authority
- `VerifyFull` - Use SSL, verify CA, and verify hostname

### 5. Connection Pooling Best Practices

Configure appropriate pool settings:
```
Host=your-host;Port=5432;Database=productmanagement;Username=app_user;Password=env_password;
Pooling=true;
Minimum Pool Size=5;
Maximum Pool Size=100;
Connection Lifetime=300;
Connection Idle Lifetime=60;
```

### 6. Logging and Monitoring

**⚠️ CRITICAL**: Never log connection strings or credentials

```csharp
// BAD - Logs password
logger.LogInformation($"Connecting with: {connectionString}");

// GOOD - Logs safe connection info only
var builder = new NpgsqlConnectionStringBuilder(connectionString);
logger.LogInformation($"Connecting to database: {builder.Database} at {builder.Host}");
```

## Pre-Production Deployment Checklist

- [ ] Remove hardcoded credentials from appsettings.json
- [ ] Implement environment variables or secure vault solution
- [ ] Create dedicated database user with minimal permissions
- [ ] Enable SSL/TLS for database connections
- [ ] Configure appropriate connection pooling settings
- [ ] Verify connection string is not logged
- [ ] Test connection with production-like credentials
- [ ] Document credential rotation procedures
- [ ] Set up monitoring and alerting for connection failures
- [ ] Review security audit logs

## Additional Security Considerations

### Input Validation
- All user inputs are currently parameterized (✅ Good)
- Continue using `NpgsqlParameter` to prevent SQL injection

### Error Handling
- Ensure error messages don't leak sensitive information
- Log detailed errors server-side only
- Return generic error messages to users

### Network Security
- Use firewalls to restrict database access
- Consider VPN or private network for database connections
- Use network segmentation to isolate database tier

### Regular Security Maintenance
- Keep Npgsql package updated
- Apply PostgreSQL security patches promptly
- Rotate credentials regularly
- Review and audit database access logs
- Perform periodic security assessments

## References

- [Npgsql Security Documentation](https://www.npgsql.org/doc/security.html)
- [PostgreSQL SSL/TLS Documentation](https://www.postgresql.org/docs/current/ssl-tcp.html)
- [.NET Configuration Best Practices](https://learn.microsoft.com/en-us/aspnet/core/security/)
- [OWASP Database Security](https://owasp.org/www-project-database-security/)

---

**Last Updated**: January 27, 2026  
**Version**: 1.0  
**Status**: Required for production deployment
