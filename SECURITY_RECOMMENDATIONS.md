# Security Recommendations for Production Deployment

## Overview
This document outlines critical security improvements required before deploying the AdoCore application to production environments.

## 1. Database Credentials Management

### Current State
The application currently uses hardcoded database credentials in `appsettings.json`:
```json
"ProdConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;Pooling=true"
```

### ⚠️ Security Risk
- Credentials are stored in plain text in source control
- Using default `postgres/postgres` credentials is highly insecure
- Anyone with access to the repository can see production credentials

### ✅ Recommended Solutions

#### Option 1: Environment Variables (Recommended for Cloud Deployments)
1. **Update Program.cs or Startup Configuration:**
```csharp
var builder = WebApplication.CreateBuilder(args);

// Override connection string with environment variable if present
var connectionString = Environment.GetEnvironmentVariable("DATABASE_CONNECTION_STRING") 
    ?? builder.Configuration.GetConnectionString("DevConnection");

builder.Services.AddSingleton(connectionString);
```

2. **Set environment variables on deployment platform:**
   - **Azure App Service:** Use Application Settings
   - **AWS Elastic Beanstalk:** Use Environment Properties
   - **Docker:** Use `-e` flag or docker-compose environment section
   - **Kubernetes:** Use Secrets and ConfigMaps

#### Option 2: Azure Key Vault (Azure Deployments)
1. **Install Package:**
```bash
dotnet add package Azure.Extensions.AspNetCore.Configuration.Secrets
dotnet add package Azure.Identity
```

2. **Update Program.cs:**
```csharp
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

var keyVaultUrl = new Uri("https://your-keyvault.vault.azure.net/");
var credential = new DefaultAzureCredential();
builder.Configuration.AddAzureKeyVault(keyVaultUrl, credential);
```

3. **Store connection string in Key Vault:**
```bash
az keyvault secret set --vault-name "your-keyvault" --name "DatabaseConnectionString" --value "Host=..."
```

#### Option 3: AWS Secrets Manager (AWS Deployments)
1. **Install Package:**
```bash
dotnet add package Amazon.Extensions.Configuration.SystemsManager
```

2. **Update Program.cs:**
```csharp
using Amazon.Extensions.NETCore.Setup;

builder.Configuration.AddSecretsManager(region: RegionEndpoint.USEast1);
```

3. **Store connection string in Secrets Manager:**
```bash
aws secretsmanager create-secret --name "AdoCore/DatabaseConnectionString" --secret-string "Host=..."
```

#### Option 4: User Secrets (Development Only)
For local development (NOT for production):
```bash
dotnet user-secrets init
dotnet user-secrets set "ConnectionStrings:ProdConnection" "Host=localhost;Port=5432;Database=ProductManagement;Username=devuser;Password=devpass;Pooling=true"
```

## 2. Database Account Security

### Current Issue
Using the `postgres` superuser account for application access.

### ✅ Recommendations

1. **Create a dedicated application user:**
```sql
-- Create application-specific role
CREATE ROLE adocore_app WITH LOGIN PASSWORD 'strong_password_here';

-- Grant minimal required permissions
GRANT CONNECT ON DATABASE ProductManagement TO adocore_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO adocore_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO adocore_app;
```

2. **Use least privilege principle:**
   - Application should NOT have DDL permissions (CREATE, DROP, ALTER)
   - Application should NOT have superuser privileges
   - Consider read-only roles for reporting queries

3. **Implement connection pooling limits:**
```
Pooling=true;Minimum Pool Size=5;Maximum Pool Size=20;Connection Lifetime=300
```

## 3. Connection String Security Best Practices

### ✅ Secure Connection String Template
```
Host={db_host};
Port={db_port};
Database={db_name};
Username={app_user};
Password={secure_password};
Pooling=true;
Minimum Pool Size=5;
Maximum Pool Size=20;
Connection Lifetime=300;
SSL Mode=Require;
Trust Server Certificate=false
```

### SSL/TLS Configuration
For production PostgreSQL:
1. Enable SSL on PostgreSQL server
2. Use `SSL Mode=Require` or `SSL Mode=VerifyFull` in connection string
3. Distribute CA certificates for certificate validation

## 4. Additional Security Measures

### Password Requirements
- Minimum 16 characters
- Include uppercase, lowercase, numbers, and special characters
- Rotate passwords every 90 days
- Never reuse passwords across environments

### Network Security
- Restrict database access to application servers only (firewall rules)
- Use private network connections when possible
- Implement VPN or VPC peering for cloud deployments
- Enable PostgreSQL's `pg_hba.conf` IP restrictions

### Monitoring and Auditing
- Enable PostgreSQL audit logging
- Monitor failed login attempts
- Track connection pool exhaustion
- Set up alerts for unusual database activity

### Secrets Rotation
- Implement automated credential rotation
- Update application configuration without downtime
- Maintain audit trail of credential changes

## 5. Pre-Production Checklist

Before deploying to production:
- [ ] Remove hardcoded credentials from appsettings.json
- [ ] Implement one of the recommended secrets management solutions
- [ ] Create dedicated database application user with least privileges
- [ ] Enable SSL/TLS for database connections
- [ ] Configure connection pooling appropriately
- [ ] Set up firewall rules restricting database access
- [ ] Enable database audit logging
- [ ] Document incident response procedures for credential leaks
- [ ] Test credential rotation process
- [ ] Verify backup and recovery procedures

## 6. Incident Response

If credentials are accidentally committed to source control:
1. **Immediately** rotate the exposed credentials
2. Review access logs for unauthorized access
3. Update all environments with new credentials
4. Remove credentials from Git history using `git-filter-repo` or BFG Repo-Cleaner
5. Force push cleaned repository (coordinate with team)
6. Conduct security review to prevent recurrence

## References

- [ASP.NET Core Configuration Best Practices](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/configuration/)
- [Azure Key Vault Configuration Provider](https://learn.microsoft.com/en-us/aspnet/core/security/key-vault-configuration)
- [AWS Secrets Manager for .NET](https://docs.aws.amazon.com/secretsmanager/latest/userguide/retrieving-secrets.html)
- [Npgsql Security Documentation](https://www.npgsql.org/doc/security.html)
- [PostgreSQL Security Best Practices](https://www.postgresql.org/docs/current/auth-pg-hba-conf.html)

---

**Document Version:** 1.0  
**Last Updated:** 2026-01-29  
**Migration Phase:** Post-Migration Security Hardening
