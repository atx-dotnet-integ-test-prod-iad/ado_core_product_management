# Security Configuration Guide

## Overview

This document describes the security improvements made to the AdoCore application during the PostgreSQL migration, including credential management, package updates, and deployment best practices.

## Security Updates Applied

### 1. Npgsql Package Update (CRITICAL)

**Issue:** Npgsql 8.0.0 had a known high severity vulnerability (GHSA-x9vc-6hfv-hg8c)

**Resolution:** Updated to Npgsql 8.0.5

**Verification:**
```bash
dotnet list package
# Should show: Npgsql version 8.0.5 or higher
```

**Build Verification:** The security vulnerability warning is no longer present in build output.

### 2. Environment Variable-Based Credential Management

**Issue:** Hardcoded database credentials (postgres/postgres) in appsettings.json

**Resolution:** Implemented environment variable-based configuration with fallback to appsettings.json

**Implementation Details:**

The application now checks for environment variables in this order:
1. `DB_PASSWORD` - If set, all environment variables are used
2. Falls back to appsettings.json if `DB_PASSWORD` is not set
3. Warns user if default/placeholder credentials are detected

**Code Location:** `DataAccess/ProductRepository.cs` constructor

## Environment Variables

### Required Variables

| Variable | Description | Default (Dev) | Required for Prod |
|----------|-------------|---------------|-------------------|
| DB_HOST | PostgreSQL hostname | localhost | YES |
| DB_PORT | PostgreSQL port | 5432 | NO (defaults to 5432) |
| DB_NAME | Database name | ProductManagement | YES |
| DB_USER | PostgreSQL username | postgres | YES |
| DB_PASSWORD | PostgreSQL password | (none) | **YES - CRITICAL** |

### Setting Environment Variables

#### Development Environment

**Windows PowerShell:**
```powershell
$env:DB_HOST = "localhost"
$env:DB_PORT = "5432"
$env:DB_NAME = "ProductManagement"
$env:DB_USER = "dev_user"
$env:DB_PASSWORD = "secure_dev_password_here"

# Verify
dotnet run
```

**Windows Command Prompt:**
```cmd
set DB_HOST=localhost
set DB_PORT=5432
set DB_NAME=ProductManagement
set DB_USER=dev_user
set DB_PASSWORD=secure_dev_password_here
```

**Linux/macOS:**
```bash
export DB_HOST="localhost"
export DB_PORT="5432"
export DB_NAME="ProductManagement"
export DB_USER="dev_user"
export DB_PASSWORD="secure_dev_password_here"

# Optional: Add to ~/.bashrc or ~/.zshrc for persistence
echo 'export DB_PASSWORD="secure_dev_password_here"' >> ~/.bashrc
```

#### Production Environment

**NEVER hardcode production credentials. Use one of these secure methods:**

### AWS Deployments

#### Option 1: AWS Systems Manager Parameter Store
```bash
# Store parameters
aws ssm put-parameter --name "/adocore/prod/db_host" --value "prod-db.amazonaws.com" --type String
aws ssm put-parameter --name "/adocore/prod/db_password" --value "secure_password" --type SecureString

# Retrieve in startup script
export DB_HOST=$(aws ssm get-parameter --name "/adocore/prod/db_host" --query "Parameter.Value" --output text)
export DB_PASSWORD=$(aws ssm get-parameter --name "/adocore/prod/db_password" --with-decryption --query "Parameter.Value" --output text)
```

#### Option 2: AWS Secrets Manager
```bash
# Create secret
aws secretsmanager create-secret --name adocore/prod/db --secret-string '{
  "host": "prod-db.amazonaws.com",
  "port": "5432",
  "database": "ProductManagement",
  "username": "prod_user",
  "password": "secure_password"
}'

# Retrieve in application or startup script
SECRET=$(aws secretsmanager get-secret-value --secret-id adocore/prod/db --query SecretString --output text)
export DB_HOST=$(echo $SECRET | jq -r .host)
export DB_PASSWORD=$(echo $SECRET | jq -r .password)
```

#### Option 3: EC2 Instance User Data
```bash
#!/bin/bash
# In EC2 User Data script
export DB_HOST="prod-db.amazonaws.com"
export DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id adocore/prod/password --query SecretString --output text)

cd /opt/adocore
dotnet run
```

### Azure Deployments

#### Azure Key Vault
```bash
# Store secrets in Key Vault
az keyvault secret set --vault-name MyKeyVault --name "DB-PASSWORD" --value "secure_password"

# In application, use Azure.Identity and Azure.Security.KeyVault.Secrets
# Or retrieve in startup:
DB_PASSWORD=$(az keyvault secret show --vault-name MyKeyVault --name DB-PASSWORD --query value -o tsv)
```

#### Azure App Service Application Settings
```bash
# Set environment variables in App Service
az webapp config appsettings set --name myapp --resource-group mygroup --settings \
  DB_HOST="mydb.postgres.database.azure.com" \
  DB_PORT="5432" \
  DB_NAME="ProductManagement" \
  DB_USER="adminuser@mydb" \
  DB_PASSWORD="secure_password"
```

### Docker Deployments

#### Docker Compose with .env file
```yaml
# docker-compose.yml
version: '3.8'
services:
  adocore:
    image: adocore:latest
    environment:
      - DB_HOST=${DB_HOST}
      - DB_PORT=${DB_PORT}
      - DB_NAME=${DB_NAME}
      - DB_USER=${DB_USER}
      - DB_PASSWORD=${DB_PASSWORD}
    env_file:
      - .env.production  # Never commit this file!
```

```bash
# .env.production (add to .gitignore!)
DB_HOST=prod-db.example.com
DB_PORT=5432
DB_NAME=ProductManagement
DB_USER=prod_user
DB_PASSWORD=secure_password
```

#### Kubernetes Secrets
```yaml
# Create secret
apiVersion: v1
kind: Secret
metadata:
  name: adocore-db-secret
type: Opaque
stringData:
  db-password: secure_password

---
# Use in deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: adocore
spec:
  template:
    spec:
      containers:
      - name: adocore
        env:
        - name: DB_HOST
          value: "prod-db.example.com"
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: adocore-db-secret
              key: db-password
```

## Credential Management Best Practices

### DO:
✅ Use environment variables for all sensitive credentials
✅ Use cloud provider secret management services (AWS Secrets Manager, Azure Key Vault)
✅ Rotate passwords regularly
✅ Use principle of least privilege for database users
✅ Enable SSL/TLS for database connections in production
✅ Add `.env` files to `.gitignore`
✅ Use different credentials for dev/staging/production
✅ Audit and log credential access

### DON'T:
❌ Hardcode passwords in source code
❌ Commit credentials to version control
❌ Use default credentials (postgres/postgres) in production
❌ Share credentials via email or chat
❌ Use the same credentials across multiple environments
❌ Store credentials in plain text files in production
❌ Use weak passwords

## Connection String Security

### Current Implementation

The application builds connection strings in this order:

1. **Environment Variables (Highest Priority):**
   - If `DB_PASSWORD` environment variable is set, all connection parameters are read from environment variables
   - Falls back to appsettings.json defaults for any missing variables

2. **Configuration File (Fallback):**
   - Uses `appsettings.json` if `DB_PASSWORD` is not set
   - Displays warning if placeholder credentials detected

### Secure Connection String Example

```
Host=prod-db.example.com;Port=5432;Database=ProductManagement;Username=app_user;Password=<from-env>;SSL Mode=Require;Trust Server Certificate=false
```

### SSL/TLS Configuration (Recommended for Production)

Add to connection string:
```
;SSL Mode=Require;Trust Server Certificate=false
```

Or use environment variable:
```bash
export DB_SSL_MODE="Require"
```

## Testing Security Configuration

### Verify Environment Variables are Used
```bash
# Set environment variable
export DB_PASSWORD="test_password"

# Run application - should NOT show warning
dotnet run

# Expected: No credential warning
# If you see "WARNING: Using default or placeholder credentials" - environment variables not set correctly
```

### Verify Fallback to appsettings.json
```bash
# Unset environment variable
unset DB_PASSWORD

# Run application
dotnet run

# Expected: "WARNING: Using default or placeholder credentials"
```

## Audit and Compliance

### Logging
- Connection string is built but never logged
- Only credential warnings are displayed to console
- Actual passwords never appear in logs

### Access Control
- Database user should have minimum required privileges
- Use separate users for application and admin tasks
- Consider read-only users for reporting/analytics

### Monitoring
- Monitor failed connection attempts
- Alert on credential warnings in production
- Track password rotation schedules

## Migration Security Notes

### Changes Made During PostgreSQL Migration

1. **Package Update:** Microsoft.Data.SqlClient → Npgsql 8.0.5
2. **Connection String Format:** SQL Server format → PostgreSQL format
3. **Credential Management:** Hardcoded → Environment variable-based
4. **Configuration:** Added PostgreSQL section to appsettings.json
5. **Warning System:** Added credential warning in ProductRepository constructor

### Security Improvements

- Eliminated high severity vulnerability (GHSA-x9vc-6hfv-hg8c)
- Removed hardcoded default credentials
- Added environment variable support
- Documented secure deployment practices
- Added credential usage warnings

## Troubleshooting

### Issue: "Password required" error
**Solution:** Set `DB_PASSWORD` environment variable

### Issue: "WARNING: Using default or placeholder credentials"
**Solution:** Either update appsettings.json with real credentials OR set environment variables

### Issue: Connection timeout
**Solution:** Verify `DB_HOST` and `DB_PORT` are correct, PostgreSQL is running

### Issue: Authentication failed
**Solution:** Verify `DB_USER` and `DB_PASSWORD` are correct, user exists in PostgreSQL

## References

- [Npgsql Documentation](https://www.npgsql.org/doc/)
- [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/)
- [Azure Key Vault](https://azure.microsoft.com/en-us/services/key-vault/)
- [.NET Configuration](https://docs.microsoft.com/en-us/dotnet/core/extensions/configuration)
- [GHSA-x9vc-6hfv-hg8c](https://github.com/advisories/GHSA-x9vc-6hfv-hg8c)

## Last Updated

This security configuration was implemented during the SQL Server to PostgreSQL migration completed on [Current Date].

For questions or security concerns, please contact the development team.
