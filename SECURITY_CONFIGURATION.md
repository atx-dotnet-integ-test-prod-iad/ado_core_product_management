# Security Configuration Guide

## ⚠️ CRITICAL: Database Credentials Security

### Current Configuration Status
The application currently uses **hardcoded database credentials** in `appsettings.json`:
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres;Port=5432"
  }
}
```

**This is NOT secure for production environments.**

---

## Recommended Security Practices

### 1. Environment Variables (Recommended for Production)

#### Option A: Using Environment Variables Directly
Replace the connection string configuration with environment variable references:

**Update Program.cs or Startup:**
```csharp
var host = Environment.GetEnvironmentVariable("POSTGRES_HOST") ?? "localhost";
var database = Environment.GetEnvironmentVariable("POSTGRES_DATABASE") ?? "ProductManagement";
var username = Environment.GetEnvironmentVariable("POSTGRES_USERNAME");
var password = Environment.GetEnvironmentVariable("POSTGRES_PASSWORD");
var port = Environment.GetEnvironmentVariable("POSTGRES_PORT") ?? "5432";

var connectionString = $"Host={host};Database={database};Username={username};Password={password};Port={port}";
```

**Set environment variables:**
```bash
# Linux/macOS
export POSTGRES_HOST=your-postgres-host
export POSTGRES_DATABASE=ProductManagement
export POSTGRES_USERNAME=your-username
export POSTGRES_PASSWORD=your-secure-password
export POSTGRES_PORT=5432

# Windows PowerShell
$env:POSTGRES_HOST="your-postgres-host"
$env:POSTGRES_DATABASE="ProductManagement"
$env:POSTGRES_USERNAME="your-username"
$env:POSTGRES_PASSWORD="your-secure-password"
$env:POSTGRES_PORT="5432"
```

#### Option B: Using User Secrets (Development Only)
For local development, use .NET User Secrets:

```bash
# Initialize user secrets
cd sourceCode
dotnet user-secrets init

# Add connection string
dotnet user-secrets set "ConnectionStrings:DevConnection" "Host=localhost;Database=ProductManagement;Username=postgres;Password=your-password;Port=5432"
```

**Update Program.cs:**
```csharp
// In development, this automatically loads user secrets
var builder = WebApplication.CreateBuilder(args);
// or for console apps:
var configuration = new ConfigurationBuilder()
    .AddJsonFile("appsettings.json", optional: false)
    .AddUserSecrets<Program>()  // Adds user secrets in development
    .AddEnvironmentVariables()
    .Build();
```

---

### 2. AWS Secrets Manager (Recommended for AWS Deployments)

Store database credentials in AWS Secrets Manager and retrieve at runtime:

**Install AWS SDK:**
```bash
dotnet add package AWSSDK.SecretsManager
```

**Retrieve secrets at runtime:**
```csharp
using Amazon.SecretsManager;
using Amazon.SecretsManager.Model;
using System.Text.Json;

public class SecretsService
{
    public async Task<string> GetConnectionStringAsync()
    {
        string secretName = "prod/postgresql/credentials";
        string region = "us-east-1";

        IAmazonSecretsManager client = new AmazonSecretsManagerClient(
            Amazon.RegionEndpoint.GetBySystemName(region)
        );

        GetSecretValueRequest request = new GetSecretValueRequest
        {
            SecretId = secretName,
            VersionStage = "AWSCURRENT"
        };

        GetSecretValueResponse response = await client.GetSecretValueAsync(request);
        
        var secret = JsonSerializer.Deserialize<DatabaseCredentials>(response.SecretString);
        
        return $"Host={secret.Host};Database={secret.Database};Username={secret.Username};Password={secret.Password};Port={secret.Port}";
    }
}

public class DatabaseCredentials
{
    public string Host { get; set; }
    public string Database { get; set; }
    public string Username { get; set; }
    public string Password { get; set; }
    public string Port { get; set; }
}
```

**Create secret in AWS Secrets Manager:**
```bash
aws secretsmanager create-secret \
    --name prod/postgresql/credentials \
    --secret-string '{"Host":"your-rds-endpoint","Database":"ProductManagement","Username":"your-user","Password":"your-secure-password","Port":"5432"}' \
    --region us-east-1
```

---

### 3. Azure Key Vault (For Azure Deployments)

**Install Azure packages:**
```bash
dotnet add package Azure.Identity
dotnet add package Azure.Extensions.AspNetCore.Configuration.Secrets
```

**Configure in Program.cs:**
```csharp
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

var builder = WebApplication.CreateBuilder(args);

// Add Azure Key Vault
var keyVaultEndpoint = new Uri(Environment.GetEnvironmentVariable("VaultUri"));
builder.Configuration.AddAzureKeyVault(keyVaultEndpoint, new DefaultAzureCredential());
```

---

### 4. Docker Secrets (For Containerized Deployments)

**docker-compose.yml:**
```yaml
version: '3.8'
services:
  app:
    image: adocore:latest
    environment:
      - POSTGRES_HOST=postgres
      - POSTGRES_DATABASE=ProductManagement
      - POSTGRES_PORT=5432
    secrets:
      - postgres_username
      - postgres_password
    
secrets:
  postgres_username:
    external: true
  postgres_password:
    external: true
```

**Create secrets:**
```bash
echo "your-username" | docker secret create postgres_username -
echo "your-password" | docker secret create postgres_password -
```

---

## Security Checklist

- [ ] **Remove hardcoded credentials from appsettings.json**
- [ ] **Use environment variables or secret management service**
- [ ] **Enable SSL/TLS for PostgreSQL connections** (add `SslMode=Require` to connection string)
- [ ] **Use least-privilege database user** (not 'postgres' superuser)
- [ ] **Rotate database credentials regularly**
- [ ] **Never commit secrets to version control**
- [ ] **Add appsettings.Production.json to .gitignore**
- [ ] **Use different credentials for dev/staging/production**
- [ ] **Enable connection pooling** (Npgsql does this by default)
- [ ] **Set connection timeout limits** (add `Timeout=30;Command Timeout=30`)
- [ ] **Monitor and log failed connection attempts**

---

## Connection String Security Enhancements

### Recommended Production Connection String Format
```
Host=your-host.rds.amazonaws.com;
Database=ProductManagement;
Username=app_user;
Password=<from-secrets-manager>;
Port=5432;
SslMode=Require;
Trust Server Certificate=false;
Timeout=30;
Command Timeout=30;
Pooling=true;
Minimum Pool Size=0;
Maximum Pool Size=100;
```

### Security Parameters Explained
- **SslMode=Require**: Enforces encrypted connections
- **Trust Server Certificate=false**: Validates SSL certificate
- **Timeout=30**: Prevents hung connections
- **Command Timeout=30**: Prevents long-running queries from hanging
- **Pooling=true**: Reuses connections for better performance
- **Maximum Pool Size=100**: Limits concurrent connections

---

## Migration from Current Configuration

### Step 1: Backup Current Configuration
```bash
cp appsettings.json appsettings.json.backup
```

### Step 2: Update appsettings.json (Remove Credentials)
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Database=ProductManagement;Port=5432;SslMode=Prefer",
    "ProdConnection": ""
  },
  "Environment": "Development"
}
```

### Step 3: Set Environment Variables
See sections above for your deployment platform.

### Step 4: Test Connection
```bash
dotnet run
# Verify application can connect using environment variables
```

---

## Additional Resources

- [Npgsql Connection String Documentation](https://www.npgsql.org/doc/connection-string-parameters.html)
- [.NET User Secrets](https://learn.microsoft.com/en-us/aspnet/core/security/app-secrets)
- [AWS Secrets Manager .NET SDK](https://docs.aws.amazon.com/secretsmanager/latest/userguide/retrieving-secrets-sdk.html)
- [Azure Key Vault for .NET](https://learn.microsoft.com/en-us/azure/key-vault/general/tutorial-net-create-vault-azure-web-app)

---

## Contact & Support

For security concerns or questions about implementing these practices, consult your security team or DevOps engineers before deploying to production.

**Last Updated:** 2026-01-16  
**Migration Context:** SQL Server to PostgreSQL ADO.NET Migration
