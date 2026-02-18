# Security Policy

## 🔒 Critical Security Requirements

This document outlines the **MANDATORY** security requirements that must be addressed before deploying this application to production.

## ⚠️ Current Security Issues

### 1. CRITICAL: Hardcoded Database Credentials

**Status**: 🔴 MUST BE FIXED BEFORE PRODUCTION

**Issue**: The `appsettings.json` file contains placeholder credentials:
```json
"Username=postgres;Password=postgres"
```

**Risk**: 
- Credentials are exposed in source code
- Anyone with repository access can access the database
- Credentials may be leaked in version control history
- CVSS Score: HIGH

**Required Action**: Replace with secure credential management

### 2. Package Vulnerability (RESOLVED)

**Status**: ✅ RESOLVED

**Issue**: Npgsql 8.0.0 had a known high severity vulnerability (GHSA-x9vc-6hfv-hg8c)

**Resolution**: Upgraded to Npgsql 10.0.1

## Secure Credential Management Solutions

### Option 1: Environment Variables (Minimum Requirement)

**Setup**:
```bash
# Linux/macOS
export DB_HOST="your-db-host"
export DB_PORT="5432"
export DB_NAME="ProductManagement"
export DB_USER="your-secure-username"
export DB_PASSWORD="your-secure-password"

# Windows PowerShell
$env:DB_HOST="your-db-host"
$env:DB_PORT="5432"
$env:DB_NAME="ProductManagement"
$env:DB_USER="your-secure-username"
$env:DB_PASSWORD="your-secure-password"
```

**Application Configuration**:
Update your configuration loading in `Program.cs`:
```csharp
var host = Environment.GetEnvironmentVariable("DB_HOST");
var port = Environment.GetEnvironmentVariable("DB_PORT");
var database = Environment.GetEnvironmentVariable("DB_NAME");
var user = Environment.GetEnvironmentVariable("DB_USER");
var password = Environment.GetEnvironmentVariable("DB_PASSWORD");

var connectionString = $"Host={host};Port={port};Database={database};Username={user};Password={password};Pooling=true;MaxPoolSize=100";
```

### Option 2: AWS Secrets Manager (Recommended for AWS)

**Prerequisites**:
```bash
dotnet add package AWSSDK.SecretsManager
```

**Implementation**:
```csharp
using Amazon.SecretsManager;
using Amazon.SecretsManager.Model;

public class SecretsManagerService
{
    private readonly IAmazonSecretsManager _client;
    
    public SecretsManagerService()
    {
        _client = new AmazonSecretsManagerClient();
    }
    
    public async Task<string> GetSecretAsync(string secretName)
    {
        var request = new GetSecretValueRequest
        {
            SecretId = secretName
        };
        
        var response = await _client.GetSecretValueAsync(request);
        return response.SecretString;
    }
}

// Usage in Program.cs
var secretService = new SecretsManagerService();
var connectionString = await secretService.GetSecretAsync("prod/database/connection");
```

**AWS Secrets Manager Setup**:
```bash
# Create secret
aws secretsmanager create-secret \
    --name prod/database/connection \
    --secret-string '{"host":"your-host","port":"5432","database":"ProductManagement","username":"your-user","password":"your-password"}'

# Grant IAM permissions
aws iam attach-role-policy \
    --role-name YourAppRole \
    --policy-arn arn:aws:iam::aws:policy/SecretsManagerReadWrite
```

### Option 3: Azure Key Vault (Recommended for Azure)

**Prerequisites**:
```bash
dotnet add package Azure.Identity
dotnet add package Azure.Security.KeyVault.Secrets
```

**Implementation**:
```csharp
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

public class KeyVaultService
{
    private readonly SecretClient _client;
    
    public KeyVaultService(string keyVaultUrl)
    {
        _client = new SecretClient(
            new Uri(keyVaultUrl),
            new DefaultAzureCredential()
        );
    }
    
    public async Task<string> GetSecretAsync(string secretName)
    {
        var secret = await _client.GetSecretAsync(secretName);
        return secret.Value.Value;
    }
}

// Usage in Program.cs
var keyVaultService = new KeyVaultService("https://your-vault.vault.azure.net/");
var dbPassword = await keyVaultService.GetSecretAsync("database-password");
```

### Option 4: Docker Secrets (For Docker/Kubernetes)

**Docker Compose**:
```yaml
version: '3.8'
services:
  app:
    image: your-app:latest
    secrets:
      - db_password
    environment:
      DB_HOST: postgres
      DB_PORT: 5432
      DB_NAME: ProductManagement
      DB_USER: app_user
      DB_PASSWORD_FILE: /run/secrets/db_password

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

**Kubernetes**:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: database-credentials
type: Opaque
data:
  password: <base64-encoded-password>
---
apiVersion: v1
kind: Pod
metadata:
  name: app
spec:
  containers:
  - name: app
    image: your-app:latest
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: database-credentials
          key: password
```

## Database Connection Security

### Required Connection String Parameters for Production

```
Host=<host>;
Port=5432;
Database=ProductManagement;
Username=<secure-user>;
Password=<from-secrets-manager>;
SslMode=Require;                    # REQUIRED: Enforce SSL/TLS
Pooling=true;
MaxPoolSize=100;
MinPoolSize=10;
ConnectionIdleLifetime=300;
ConnectionPruningInterval=10;
```

### SSL/TLS Configuration

**PostgreSQL Server Configuration** (`postgresql.conf`):
```conf
ssl = on
ssl_cert_file = '/path/to/server.crt'
ssl_key_file = '/path/to/server.key'
ssl_ca_file = '/path/to/root.crt'
```

**Client Configuration** (`appsettings.json`):
```json
{
  "ConnectionStrings": {
    "ProdConnection": "Host=...;SslMode=Require;Trust Server Certificate=false;SSL Certificate=/path/to/client.crt"
  }
}
```

## Database User Permissions

### Principle of Least Privilege

Create a dedicated application user with minimum required permissions:

```sql
-- Create application user
CREATE USER app_user WITH PASSWORD 'secure-password-from-secrets-manager';

-- Grant only required permissions
GRANT CONNECT ON DATABASE "ProductManagement" TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON "Products" TO app_user;
GRANT SELECT, INSERT ON "ProductHistory" TO app_user;
GRANT SELECT, UPDATE ON "ProductStats" TO app_user;

-- Grant sequence permissions for SERIAL columns
GRANT USAGE, SELECT ON SEQUENCE "Products_ProductId_seq" TO app_user;
GRANT USAGE, SELECT ON SEQUENCE "ProductHistory_HistoryId_seq" TO app_user;
GRANT USAGE, SELECT ON SEQUENCE "ProductStats_StatId_seq" TO app_user;

-- Revoke unnecessary permissions
REVOKE CREATE ON SCHEMA public FROM app_user;
REVOKE ALL ON DATABASE "ProductManagement" FROM PUBLIC;
```

### Do NOT Use:
- ❌ postgres superuser account
- ❌ GRANT ALL PRIVILEGES
- ❌ SUPERUSER role
- ❌ CREATEDB or CREATEROLE permissions

## Additional Security Best Practices

### 1. Never Commit Secrets to Git

**.gitignore** (verify this is configured):
```gitignore
appsettings.Production.json
appsettings.*.json
*.secrets.json
.env
.env.*
secrets/
```

### 2. Audit Existing Repository

Check if credentials were previously committed:
```bash
# Search git history for potential secrets
git log -S "Password=" --all
git log -S "postgres" --all

# If found, use git-filter-repo to remove
# IMPORTANT: This rewrites history
git filter-repo --path appsettings.json --invert-paths
```

### 3. Rotate Credentials

After securing credential management:
1. Change all database passwords
2. Update secrets in your chosen secrets manager
3. Rotate credentials regularly (every 90 days minimum)

### 4. Enable Database Audit Logging

**PostgreSQL Configuration**:
```conf
# postgresql.conf
log_connections = on
log_disconnections = on
log_statement = 'all'
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
```

### 5. Network Security

- Use private subnets for database servers
- Configure security groups to allow only application servers
- Use VPN or bastion hosts for administrative access
- Enable PostgreSQL's `pg_hba.conf` to restrict connections:

```conf
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             postgres                                peer
host    ProductManagement  app_user     10.0.0.0/8              md5
hostssl ProductManagement  app_user     0.0.0.0/0               md5
```

## Pre-Deployment Security Checklist

Before deploying to production, verify:

- [ ] No hardcoded credentials in source code
- [ ] Credentials are stored in a secure secrets manager
- [ ] Database user has minimum required permissions
- [ ] SSL/TLS is enabled and enforced
- [ ] Connection string uses SslMode=Require
- [ ] Database audit logging is enabled
- [ ] Network security groups restrict database access
- [ ] appsettings.json with production credentials is in .gitignore
- [ ] Git history has been audited for leaked credentials
- [ ] Credential rotation schedule is established
- [ ] Npgsql package is updated to 10.0.1 or later
- [ ] Integration testing completed with production-like environment
- [ ] Security scan performed on application and dependencies

## Reporting Security Issues

If you discover a security vulnerability, please report it to:
- **Email**: [security@yourcompany.com]
- **Do NOT** create public GitHub issues for security vulnerabilities

## References

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [OWASP Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [PostgreSQL Security Best Practices](https://www.postgresql.org/docs/current/security.html)
- [Npgsql Security](https://www.npgsql.org/doc/security.html)
- [AWS Secrets Manager Best Practices](https://docs.aws.amazon.com/secretsmanager/latest/userguide/best-practices.html)
- [Azure Key Vault Best Practices](https://docs.microsoft.com/en-us/azure/key-vault/general/best-practices)

## Last Updated

This security policy was last updated during the PostgreSQL migration on [Current Date].

**Next Review Date**: [30 days from current date]
