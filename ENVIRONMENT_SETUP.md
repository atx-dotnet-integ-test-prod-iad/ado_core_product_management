# Environment Variable Configuration Guide

## Overview

This application uses environment variables for PostgreSQL database credentials to enhance security and follow 12-factor app principles. This approach prevents hardcoded passwords in configuration files and source code.

## Security Benefits

✅ No passwords stored in configuration files  
✅ No passwords committed to version control  
✅ Different credentials for different environments (dev, staging, prod)  
✅ Follows industry security best practices  
✅ Compatible with secrets management systems (AWS Secrets Manager, Azure Key Vault, etc.)

## Required Environment Variable

### PGPASSWORD (REQUIRED)
The PostgreSQL database password. The application will NOT start without this variable set.

**Error if not set:**
```
PostgreSQL password not configured. Please set the PGPASSWORD environment variable.
See appsettings.json for configuration details.
```

## Optional Environment Variables

The following variables have sensible defaults but can be overridden:

| Variable | Description | Default Value |
|----------|-------------|---------------|
| PGHOST | PostgreSQL server hostname or IP | localhost |
| PGDATABASE | Database name | ProductManagement |
| PGUSER | PostgreSQL username | postgres |
| PGPORT | PostgreSQL server port | 5432 |

## Setting Environment Variables

### Linux / macOS

#### Temporary (Current Session Only)
```bash
export PGPASSWORD='your_secure_password'
export PGHOST='localhost'
export PGDATABASE='ProductManagement'
export PGUSER='postgres'
export PGPORT='5432'
```

#### Permanent (All Sessions)

**For bash:**
Add to `~/.bashrc`:
```bash
echo "export PGPASSWORD='your_secure_password'" >> ~/.bashrc
echo "export PGHOST='localhost'" >> ~/.bashrc
echo "export PGDATABASE='ProductManagement'" >> ~/.bashrc
echo "export PGUSER='postgres'" >> ~/.bashrc
echo "export PGPORT='5432'" >> ~/.bashrc
source ~/.bashrc
```

**For zsh:**
Add to `~/.zshrc`:
```bash
echo "export PGPASSWORD='your_secure_password'" >> ~/.zshrc
echo "export PGHOST='localhost'" >> ~/.zshrc
echo "export PGDATABASE='ProductManagement'" >> ~/.zshrc
echo "export PGUSER='postgres'" >> ~/.zshrc
echo "export PGPORT='5432'" >> ~/.zshrc
source ~/.zshrc
```

### Windows

#### Command Prompt (cmd)

**Temporary (Current Session):**
```cmd
set PGPASSWORD=your_secure_password
set PGHOST=localhost
set PGDATABASE=ProductManagement
set PGUSER=postgres
set PGPORT=5432
```

**Permanent (System-wide):**
```cmd
setx PGPASSWORD "your_secure_password"
setx PGHOST "localhost"
setx PGDATABASE "ProductManagement"
setx PGUSER "postgres"
setx PGPORT "5432"
```
*Note: You need to restart your terminal after using `setx`*

#### PowerShell

**Temporary (Current Session):**
```powershell
$env:PGPASSWORD = 'your_secure_password'
$env:PGHOST = 'localhost'
$env:PGDATABASE = 'ProductManagement'
$env:PGUSER = 'postgres'
$env:PGPORT = '5432'
```

**Permanent (Current User):**
```powershell
[Environment]::SetEnvironmentVariable('PGPASSWORD', 'your_secure_password', 'User')
[Environment]::SetEnvironmentVariable('PGHOST', 'localhost', 'User')
[Environment]::SetEnvironmentVariable('PGDATABASE', 'ProductManagement', 'User')
[Environment]::SetEnvironmentVariable('PGUSER', 'postgres', 'User')
[Environment]::SetEnvironmentVariable('PGPORT', '5432', 'User')
```

**Permanent (System-wide - Requires Administrator):**
```powershell
[Environment]::SetEnvironmentVariable('PGPASSWORD', 'your_secure_password', 'Machine')
[Environment]::SetEnvironmentVariable('PGHOST', 'localhost', 'Machine')
[Environment]::SetEnvironmentVariable('PGDATABASE', 'ProductManagement', 'Machine')
[Environment]::SetEnvironmentVariable('PGUSER', 'postgres', 'Machine')
[Environment]::SetEnvironmentVariable('PGPORT', '5432', 'Machine')
```

#### Windows GUI Method

1. Open **System Properties**:
   - Right-click on "This PC" or "My Computer"
   - Select "Properties"
   - Click "Advanced system settings"
   - Click "Environment Variables"

2. Add New Variables:
   - Under "User variables" or "System variables", click "New"
   - Variable name: `PGPASSWORD`
   - Variable value: `your_secure_password`
   - Click OK
   - Repeat for other variables (PGHOST, PGDATABASE, PGUSER, PGPORT)

3. Apply and Restart:
   - Click OK on all dialogs
   - Restart your terminal/IDE for changes to take effect

## Verifying Environment Variables

### Linux / macOS
```bash
echo $PGPASSWORD
echo $PGHOST
echo $PGDATABASE
echo $PGUSER
echo $PGPORT
```

### Windows Command Prompt
```cmd
echo %PGPASSWORD%
echo %PGHOST%
echo %PGDATABASE%
echo %PGUSER%
echo %PGPORT%
```

### Windows PowerShell
```powershell
$env:PGPASSWORD
$env:PGHOST
$env:PGDATABASE
$env:PGUSER
$env:PGPORT
```

## Development Environment Setup

For local development, you typically only need to set PGPASSWORD:

```bash
# Linux/macOS
export PGPASSWORD='your_dev_password'

# Windows Command Prompt
set PGPASSWORD=your_dev_password

# Windows PowerShell
$env:PGPASSWORD = 'your_dev_password'
```

The application will use the defaults for other settings:
- Host: localhost
- Database: ProductManagement
- User: postgres
- Port: 5432

## Production Environment Setup

For production deployments, use a secrets management system:

### AWS Secrets Manager
```bash
# Store secret
aws secretsmanager create-secret --name prod/postgres/password --secret-string "your_prod_password"

# Retrieve and set environment variable
export PGPASSWORD=$(aws secretsmanager get-secret-value --secret-id prod/postgres/password --query SecretString --output text)
```

### Azure Key Vault
```bash
# Store secret
az keyvault secret set --vault-name myKeyVault --name PGPASSWORD --value "your_prod_password"

# Retrieve and set environment variable
export PGPASSWORD=$(az keyvault secret show --vault-name myKeyVault --name PGPASSWORD --query value -o tsv)
```

### Docker / Docker Compose
```yaml
# docker-compose.yml
version: '3.8'
services:
  app:
    image: your-app-image
    environment:
      - PGPASSWORD=${PGPASSWORD}
      - PGHOST=postgres-server
      - PGDATABASE=ProductManagement
      - PGUSER=postgres
      - PGPORT=5432
```

### Kubernetes
```yaml
# secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-credentials
type: Opaque
stringData:
  PGPASSWORD: "your_password_here"
---
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: adocore-app
spec:
  template:
    spec:
      containers:
      - name: app
        image: your-app-image
        env:
        - name: PGPASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-credentials
              key: PGPASSWORD
        - name: PGHOST
          value: "postgres-service"
        - name: PGDATABASE
          value: "ProductManagement"
        - name: PGUSER
          value: "postgres"
        - name: PGPORT
          value: "5432"
```

## Troubleshooting

### Issue: "PostgreSQL password not configured" error
**Solution:** 
1. Verify PGPASSWORD is set: `echo $PGPASSWORD` (Linux/macOS) or `echo %PGPASSWORD%` (Windows)
2. If empty, set the variable following instructions above
3. If using IDE, restart the IDE after setting system environment variables

### Issue: Environment variable not recognized
**Solution:**
- Restart your terminal/command prompt/PowerShell after setting variables
- If using an IDE (Visual Studio, VS Code, Rider), restart it
- For system-wide variables on Windows, log out and log back in

### Issue: Connection fails despite correct password
**Solution:**
1. Verify all connection parameters:
   ```bash
   echo $PGHOST $PGDATABASE $PGUSER $PGPORT
   ```
2. Test PostgreSQL connection manually:
   ```bash
   psql -h $PGHOST -U $PGUSER -d $PGDATABASE -p $PGPORT
   ```
3. Ensure PostgreSQL server is running
4. Check firewall settings if connecting to remote server

### Issue: Password contains special characters
**Solution:**
- Use single quotes when setting: `export PGPASSWORD='p@ssw0rd!'`
- In PowerShell, escape special characters or use single quotes
- For environment variable files (.env), quote the value

## Best Practices

1. ✅ **Never commit passwords to version control**
   - Add `.env` files to `.gitignore`
   - Use environment-specific configuration

2. ✅ **Use different passwords for each environment**
   - Development: Simple password for local testing
   - Staging: Similar security to production
   - Production: Strong, unique passwords

3. ✅ **Rotate passwords regularly**
   - Update PGPASSWORD variable when password changes
   - Use secrets management rotation features

4. ✅ **Limit password exposure**
   - Set variables at the user level, not system-wide when possible
   - Use secrets management in CI/CD pipelines

5. ✅ **Document for your team**
   - Share this guide with team members
   - Document which environment variables are required

## CI/CD Integration

### GitHub Actions
```yaml
name: Build and Test
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    env:
      PGPASSWORD: ${{ secrets.PGPASSWORD }}
      PGHOST: localhost
      PGDATABASE: ProductManagement
      PGUSER: postgres
      PGPORT: 5432
    steps:
      - uses: actions/checkout@v2
      - name: Setup PostgreSQL
        uses: harmon758/postgresql-action@v1
      - name: Build
        run: dotnet build
      - name: Test
        run: dotnet test
```

### GitLab CI
```yaml
variables:
  PGHOST: "localhost"
  PGDATABASE: "ProductManagement"
  PGUSER: "postgres"
  PGPORT: "5432"

build:
  script:
    - export PGPASSWORD=$POSTGRES_PASSWORD
    - dotnet build
    - dotnet test
```

### Jenkins
```groovy
pipeline {
    environment {
        PGPASSWORD = credentials('postgres-password')
        PGHOST = 'localhost'
        PGDATABASE = 'ProductManagement'
        PGUSER = 'postgres'
        PGPORT = '5432'
    }
    stages {
        stage('Build') {
            steps {
                sh 'dotnet build'
            }
        }
    }
}
```

## Security Checklist

- [ ] PGPASSWORD is set via environment variable
- [ ] No passwords in appsettings.json
- [ ] No passwords in source code
- [ ] .env files (if used) are in .gitignore
- [ ] Different passwords for dev/staging/prod
- [ ] Production uses secrets management system
- [ ] Team members know how to set up environment variables
- [ ] CI/CD pipelines use secret storage for credentials
