# PostgreSQL Database Setup and Validation Script (PowerShell)
# This script automates the setup of PostgreSQL database for the migrated AdoCore application

param(
    [string]$PostgresHost = "localhost",
    [string]$PostgresPort = "5432",
    [string]$PostgresUser = "postgres",
    [string]$PostgresPassword = "postgres",
    [string]$PostgresDB = "ProductManagement"
)

# Configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SqlScript = Join-Path $ScriptDir "Database\Scripts\01_PostgreSQL_Setup.sql"

# Functions
function Write-Header {
    param([string]$Message)
    Write-Host "================================" -ForegroundColor Green
    Write-Host $Message -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Green
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Yellow
}

function Check-Prerequisites {
    Write-Header "Checking Prerequisites"
    
    # Check if psql is installed
    try {
        $psqlVersion = & psql --version 2>&1
        Write-Success "psql (PostgreSQL client) is installed"
        Write-Info "Version: $psqlVersion"
    } catch {
        Write-Fail "psql not found. Please install PostgreSQL client tools."
        exit 1
    }
    
    # Check if dotnet is installed
    try {
        $dotnetVersion = & dotnet --version 2>&1
        Write-Success "dotnet SDK is installed"
        Write-Info "Version: $dotnetVersion"
    } catch {
        Write-Fail "dotnet SDK not found. Please install .NET SDK."
        exit 1
    }
    
    # Check if SQL script exists
    if (Test-Path $SqlScript) {
        Write-Success "PostgreSQL setup script found"
    } else {
        Write-Fail "Setup script not found at: $SqlScript"
        exit 1
    }
    
    Write-Host ""
}

function Check-PostgresConnection {
    Write-Header "Checking PostgreSQL Connection"
    
    $env:PGPASSWORD = $PostgresPassword
    try {
        $null = & psql -h $PostgresHost -p $PostgresPort -U $PostgresUser -d postgres -c '\q' 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Connected to PostgreSQL at ${PostgresHost}:${PostgresPort}"
            return $true
        } else {
            throw "Connection failed"
        }
    } catch {
        Write-Fail "Cannot connect to PostgreSQL at ${PostgresHost}:${PostgresPort}"
        Write-Info "Please ensure PostgreSQL is running and credentials are correct"
        return $false
    } finally {
        Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
    }
    
    Write-Host ""
}

function Create-Database {
    Write-Header "Creating Database"
    
    $env:PGPASSWORD = $PostgresPassword
    
    # Check if database exists
    $dbExists = & psql -h $PostgresHost -p $PostgresPort -U $PostgresUser -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$PostgresDB'" 2>&1
    
    if ($dbExists -eq "1") {
        Write-Info "Database '$PostgresDB' already exists"
        $recreate = Read-Host "Do you want to drop and recreate it? (yes/no)"
        if ($recreate -eq "yes") {
            Write-Info "Dropping existing database..."
            & psql -h $PostgresHost -p $PostgresPort -U $PostgresUser -d postgres -c "DROP DATABASE IF EXISTS `"$PostgresDB`";" | Out-Null
            Write-Success "Database dropped"
        } else {
            Write-Info "Using existing database"
            Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
            Write-Host ""
            return
        }
    }
    
    # Create database
    Write-Info "Creating database '$PostgresDB'..."
    & psql -h $PostgresHost -p $PostgresPort -U $PostgresUser -d postgres -c "CREATE DATABASE `"$PostgresDB`";" | Out-Null
    Write-Success "Database created successfully"
    
    Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
    Write-Host ""
}

function Setup-Schema {
    Write-Header "Setting Up Database Schema"
    
    $env:PGPASSWORD = $PostgresPassword
    Write-Info "Running setup script..."
    
    try {
        $output = & psql -h $PostgresHost -p $PostgresPort -U $PostgresUser -d $PostgresDB -f $SqlScript 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Schema setup completed"
        } else {
            throw "Setup failed"
        }
    } catch {
        Write-Fail "Schema setup failed"
        Write-Info "Check $SqlScript for errors"
        exit 1
    } finally {
        Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
    }
    
    Write-Host ""
}

function Verify-Schema {
    Write-Header "Verifying Database Schema"
    
    $env:PGPASSWORD = $PostgresPassword
    
    # Check schema exists
    $schemaExists = & psql -h $PostgresHost -p $PostgresPort -U $PostgresUser -d $PostgresDB -tAc "SELECT 1 FROM information_schema.schemata WHERE schema_name='productmanagement_dbo'" 2>&1
    if ($schemaExists -eq "1") {
        Write-Success "Schema 'productmanagement_dbo' exists"
    } else {
        Write-Fail "Schema 'productmanagement_dbo' not found"
        Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
        exit 1
    }
    
    # Check tables
    $tables = @("categories", "suppliers", "products", "producthistory", "productstats")
    foreach ($table in $tables) {
        $tableExists = & psql -h $PostgresHost -p $PostgresPort -U $PostgresUser -d $PostgresDB -tAc "SELECT 1 FROM information_schema.tables WHERE table_schema='productmanagement_dbo' AND table_name='$table'" 2>&1
        if ($tableExists -eq "1") {
            Write-Success "Table '$table' exists"
        } else {
            Write-Fail "Table '$table' not found"
            Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
            exit 1
        }
    }
    
    # Check data
    $productCount = & psql -h $PostgresHost -p $PostgresPort -U $PostgresUser -d $PostgresDB -tAc "SELECT COUNT(*) FROM productmanagement_dbo.products" 2>&1
    if ([int]$productCount -gt 0) {
        Write-Success "Sample data loaded: $productCount products"
    } else {
        Write-Fail "No sample data found"
        Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
        exit 1
    }
    
    Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
    Write-Host ""
}

function Build-Application {
    Write-Header "Building .NET Application"
    
    Push-Location $ScriptDir
    
    Write-Info "Restoring NuGet packages..."
    $restoreOutput = & dotnet restore 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Packages restored"
    } else {
        Write-Fail "Package restore failed"
        Pop-Location
        exit 1
    }
    
    Write-Info "Building application..."
    $buildOutput = & dotnet build 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Build succeeded"
    } else {
        Write-Fail "Build failed"
        Pop-Location
        exit 1
    }
    
    Pop-Location
    Write-Host ""
}

function Test-Connectivity {
    Write-Header "Testing Application Connectivity"
    
    Push-Location $ScriptDir
    
    Write-Info "Attempting to list products..."
    $output = & dotnet run -- list 2>&1
    $exitCode = $LASTEXITCODE
    
    if ($exitCode -eq 0) {
        Write-Success "Application connected to database successfully"
        Write-Info "Sample output:"
        $output | Select-Object -First 10 | ForEach-Object { Write-Host $_ }
        if ($output.Count -gt 10) {
            Write-Host "... (output truncated)"
        }
    } else {
        Write-Fail "Application failed to connect to database"
        Write-Info "Error output:"
        Write-Host $output
        Pop-Location
        exit 1
    }
    
    Pop-Location
    Write-Host ""
}

function Run-CrudTests {
    Write-Header "Running CRUD Operation Tests"
    
    Push-Location $ScriptDir
    
    # Test INSERT
    Write-Info "Testing INSERT operation..."
    $insertOutput = & dotnet run -- add "Test Product" 99.99 50 "Test description" 2>&1
    if ($insertOutput -match "successfully|created|added") {
        Write-Success "INSERT operation successful"
    } else {
        Write-Fail "INSERT operation failed"
        Write-Host $insertOutput
    }
    
    # Test UPDATE
    Write-Info "Testing UPDATE operation..."
    $updateOutput = & dotnet run -- update 1 "Updated Product" 89.99 45 "Updated description" 2>&1
    if ($updateOutput -match "successfully|updated") {
        Write-Success "UPDATE operation successful"
    } else {
        Write-Fail "UPDATE operation failed"
        Write-Host $updateOutput
    }
    
    # Test SELECT by ID
    Write-Info "Testing SELECT by ID operation..."
    $getOutput = & dotnet run -- get 1 2>&1
    if ($getOutput -match "ProductId|Product") {
        Write-Success "SELECT by ID operation successful"
    } else {
        Write-Fail "SELECT by ID operation failed"
        Write-Host $getOutput
    }
    
    Pop-Location
    Write-Host ""
}

function Show-Summary {
    Write-Header "Setup Complete!"
    
    Write-Host "Database Information:" -ForegroundColor Green
    Write-Host "  Host: $PostgresHost"
    Write-Host "  Port: $PostgresPort"
    Write-Host "  Database: $PostgresDB"
    Write-Host "  Schema: productmanagement_dbo"
    Write-Host ""
    
    Write-Host "Connection String:" -ForegroundColor Green
    Write-Host "  Host=$PostgresHost;Port=$PostgresPort;Database=$PostgresDB;Username=$PostgresUser;Password=***"
    Write-Host ""
    
    Write-Host "Next Steps:" -ForegroundColor Green
    Write-Host "  1. Run the application:"
    Write-Host "     cd $ScriptDir"
    Write-Host "     dotnet run"
    Write-Host ""
    Write-Host "  2. Run CLI commands:"
    Write-Host "     dotnet run -- list"
    Write-Host "     dotnet run -- get 1"
    Write-Host ""
    Write-Host "  3. See POSTGRESQL_DEPLOYMENT_GUIDE.md for comprehensive testing"
    Write-Host ""
}

# Main execution
Write-Host "PostgreSQL Setup and Validation Script" -ForegroundColor Green
Write-Host "for AdoCore Application Migration" -ForegroundColor Green
Write-Host ""

# Run checks and setup
Check-Prerequisites

if (!(Check-PostgresConnection)) {
    $useDocker = Read-Host "Would you like to try with Docker? (yes/no)"
    if ($useDocker -eq "yes") {
        Write-Info "Starting PostgreSQL in Docker..."
        & docker run --name postgres-adocore `
            -e POSTGRES_PASSWORD=$PostgresPassword `
            -e POSTGRES_DB=$PostgresDB `
            -p "${PostgresPort}:5432" `
            -d postgres:15
        Write-Info "Waiting for PostgreSQL to start..."
        Start-Sleep -Seconds 5
        if (!(Check-PostgresConnection)) {
            Write-Fail "Failed to start PostgreSQL in Docker"
            exit 1
        }
    } else {
        exit 1
    }
}

Create-Database
Setup-Schema
Verify-Schema
Build-Application
Test-Connectivity
Run-CrudTests
Show-Summary
