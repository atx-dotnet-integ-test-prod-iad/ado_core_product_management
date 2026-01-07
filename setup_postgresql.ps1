# PostgreSQL Database Setup Script for Windows
# This script automates the database setup for the migrated ADO.NET application

$ErrorActionPreference = "Stop"

Write-Host "=========================================="
Write-Host "PostgreSQL Database Setup for AdoCore"
Write-Host "=========================================="
Write-Host ""

# Configuration
$DB_NAME = "ProductManagement"
$DB_USER = "postgres"
$DB_HOST = "localhost"
$DB_PORT = "5432"

# Prompt for password
$securePassword = Read-Host "Enter PostgreSQL password for user '$DB_USER'" -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
$DB_PASSWORD = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
Write-Host ""

# Set environment variable for psql
$env:PGPASSWORD = $DB_PASSWORD

# Check if psql is available
try {
    $null = Get-Command psql -ErrorAction Stop
    Write-Host "✓ psql client found"
} catch {
    Write-Host "ERROR: psql command not found. Please install PostgreSQL client tools and add to PATH."
    exit 1
}
Write-Host ""

# Create database if it doesn't exist
Write-Host "Creating database '$DB_NAME' (if it doesn't exist)..."
try {
    $dbExists = psql -U $DB_USER -h $DB_HOST -p $DB_PORT -tc "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" 2>$null
    if (-not $dbExists) {
        psql -U $DB_USER -h $DB_HOST -p $DB_PORT -c "CREATE DATABASE `"$DB_NAME`"" 2>&1 | Out-Null
    }
    Write-Host "✓ Database '$DB_NAME' ready"
} catch {
    Write-Host "ERROR: Failed to create database. Please check credentials and PostgreSQL service."
    Write-Host $_.Exception.Message
    exit 1
}
Write-Host ""

# Execute schema setup script
Write-Host "Executing schema setup script..."
$SCRIPT_PATH = Join-Path $PSScriptRoot "Database\Scripts\01_InitialSetup_PostgreSQL.sql"
if (-not (Test-Path $SCRIPT_PATH)) {
    Write-Host "ERROR: Schema script not found at $SCRIPT_PATH"
    exit 1
}

try {
    psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -f $SCRIPT_PATH
    Write-Host "✓ Schema setup completed"
} catch {
    Write-Host "ERROR: Failed to execute schema script."
    Write-Host $_.Exception.Message
    exit 1
}
Write-Host ""

# Verify setup
Write-Host "Verifying database setup..."
try {
    $productCount = psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -t -c "SELECT COUNT(*) FROM productmanagement_dbo.products" | Out-String
    $categoryCount = psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -t -c "SELECT COUNT(*) FROM productmanagement_dbo.categories" | Out-String
    $supplierCount = psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -t -c "SELECT COUNT(*) FROM productmanagement_dbo.suppliers" | Out-String
    
    Write-Host "✓ Products: $($productCount.Trim()) (expected: 19)"
    Write-Host "✓ Categories: $($categoryCount.Trim()) (expected: 20)"
    Write-Host "✓ Suppliers: $($supplierCount.Trim()) (expected: 8)"
} catch {
    Write-Host "⚠ Verification failed. Please check database manually."
}
Write-Host ""

# Clear password from environment
$env:PGPASSWORD = $null

# Update appsettings.json reminder
Write-Host "=========================================="
Write-Host "IMPORTANT: Update Connection String"
Write-Host "=========================================="
Write-Host ""
Write-Host "Please update appsettings.json with your actual database password:"
Write-Host ""
Write-Host "Connection string format:"
Write-Host "Host=$DB_HOST;Port=$DB_PORT;Database=$DB_NAME;Username=$DB_USER;Password=YOUR_PASSWORD;Pooling=true;MinPoolSize=1;MaxPoolSize=20"
Write-Host ""
Write-Host "For security reasons, this script does not automatically update appsettings.json."
Write-Host "Please edit it manually or use environment variables."
Write-Host ""

# Build application
Write-Host "Building application..."
$projectPath = Join-Path $PSScriptRoot "AdoCore.csproj"
if (Test-Path $projectPath) {
    try {
        dotnet build $projectPath
        Write-Host "✓ Application built successfully"
    } catch {
        Write-Host "⚠ Application build failed. Please check build.log for details."
    }
} else {
    Write-Host "⚠ AdoCore.csproj not found. Please build manually."
}
Write-Host ""

Write-Host "=========================================="
Write-Host "Database Setup Complete!"
Write-Host "=========================================="
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Update appsettings.json with your database password"
Write-Host "2. Run integration tests to verify all operations"
Write-Host "3. Review POSTGRESQL_DEPLOYMENT_GUIDE.md for additional configuration"
Write-Host ""
Write-Host "For troubleshooting, see POSTGRESQL_DEPLOYMENT_GUIDE.md"
