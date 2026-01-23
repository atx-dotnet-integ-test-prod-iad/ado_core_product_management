# Security Configuration Guide

## Database Connection Security

### Development Environment
The `appsettings.json` file contains default connection strings suitable for local development only. These include placeholder credentials that **MUST NOT** be used in production.

### Production Deployment

**CRITICAL**: Never use hardcoded credentials in production. Use one of the following secure approaches:

#### Option 1: Environment Variables (Recommended for most scenarios)
Override connection strings using environment variables with the hierarchical key format:

```bash
# Linux/Mac
export ConnectionStrings__DevConnection="Host=prod-host;Port=5432;Database=ProductManagement;Username=prod_user;Password=secure_password;SSL Mode=Require"

# Windows
set ConnectionStrings__DevConnection=Host=prod-host;Port=5432;Database=ProductManagement;Username=prod_user;Password=secure_password;SSL Mode=Require
```

#### Option 2: Azure Key Vault (For Azure deployments)
1. Store connection strings in Azure Key Vault
2. Add the Azure Key Vault configuration provider:
   ```xml
   <PackageReference Include="Azure.Extensions.AspNetCore.Configuration.Secrets" Version="1.3.0" />
   ```
3. Configure in Program.cs:
   ```csharp
   builder.Configuration.AddAzureKeyVault(
       new Uri($"https://{keyVaultName}.vault.azure.net/"),
       new DefaultAzureCredential());
   ```

#### Option 3: AWS Secrets Manager (For AWS deployments)
1. Store connection strings in AWS Secrets Manager
2. Add the AWS Secrets Manager configuration provider:
   ```xml
   <PackageReference Include="Kralizek.Extensions.Configuration.AWSSecretsManager" Version="3.0.0" />
   ```
3. Configure in Program.cs:
   ```csharp
   builder.Configuration.AddSecretsManager(region: RegionEndpoint.USEast1);
   ```

#### Option 4: User Secrets (Development only)
For local development with real credentials:
```bash
dotnet user-secrets init
dotnet user-secrets set "ConnectionStrings:DevConnection" "Host=localhost;Port=5432;Database=ProductManagement;Username=dev_user;Password=dev_password;SSL Mode=Prefer"
```

### SSL/TLS Configuration

- **Development**: `SSL Mode=Prefer` (allows unencrypted connections if SSL unavailable)
- **Production**: `SSL Mode=Require` (enforces encrypted connections)

### Best Practices

1. **Never commit real credentials** to version control
2. **Use separate credentials** for development, staging, and production
3. **Implement least privilege**: Database users should have only necessary permissions
4. **Rotate credentials regularly**: Especially after team member changes
5. **Enable SSL/TLS** for all production database connections
6. **Monitor access logs**: Track database connection attempts and queries
7. **Use connection pooling carefully**: Ensure proper disposal of connections

### Additional Security Measures

1. **Network Security**:
   - Use private networks or VPNs for database access
   - Restrict database server to specific IP addresses
   - Use firewall rules to limit access

2. **Application Security**:
   - Implement proper input validation
   - Use parameterized queries (already implemented with Npgsql)
   - Enable query logging for audit trails
   - Implement rate limiting for database operations

3. **Monitoring and Alerting**:
   - Set up alerts for failed connection attempts
   - Monitor for unusual query patterns
   - Track connection pool exhaustion

## Vulnerability Management

### Current Status
- **Npgsql**: Upgraded to version 8.0.5 to address known security vulnerabilities
- **Package Audit**: Run `dotnet list package --vulnerable` regularly to check for vulnerabilities

### Update Policy
- Review and apply security patches monthly
- Apply critical security updates immediately
- Test updates in non-production environments first

## References
- [Npgsql Security Best Practices](https://www.npgsql.org/doc/security.html)
- [.NET Configuration Providers](https://learn.microsoft.com/en-us/dotnet/core/extensions/configuration-providers)
- [PostgreSQL SSL Support](https://www.postgresql.org/docs/current/ssl-tcp.html)
