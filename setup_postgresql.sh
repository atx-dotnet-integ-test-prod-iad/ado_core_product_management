#!/bin/bash

# PostgreSQL Database Setup Script
# This script automates the database setup for the migrated ADO.NET application

set -e  # Exit on error

echo "=========================================="
echo "PostgreSQL Database Setup for AdoCore"
echo "=========================================="
echo ""

# Configuration
DB_NAME="ProductManagement"
DB_USER="postgres"
DB_HOST="localhost"
DB_PORT="5432"

# Prompt for password
echo "Enter PostgreSQL password for user '$DB_USER':"
read -s DB_PASSWORD
echo ""

# Check if PostgreSQL is running
echo "Checking PostgreSQL service status..."
if command -v systemctl &> /dev/null; then
    systemctl is-active --quiet postgresql || (echo "PostgreSQL is not running. Please start it first." && exit 1)
fi
echo "✓ PostgreSQL is running"
echo ""

# Check if psql is available
if ! command -v psql &> /dev/null; then
    echo "ERROR: psql command not found. Please install PostgreSQL client tools."
    exit 1
fi
echo "✓ psql client found"
echo ""

# Create database if it doesn't exist
echo "Creating database '$DB_NAME' (if it doesn't exist)..."
PGPASSWORD=$DB_PASSWORD psql -U $DB_USER -h $DB_HOST -p $DB_PORT -tc "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | grep -q 1 || \
PGPASSWORD=$DB_PASSWORD psql -U $DB_USER -h $DB_HOST -p $DB_PORT -c "CREATE DATABASE \"$DB_NAME\""
echo "✓ Database '$DB_NAME' ready"
echo ""

# Execute schema setup script
echo "Executing schema setup script..."
SCRIPT_PATH="$(dirname "$0")/Database/Scripts/01_InitialSetup_PostgreSQL.sql"
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "ERROR: Schema script not found at $SCRIPT_PATH"
    exit 1
fi

PGPASSWORD=$DB_PASSWORD psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -f "$SCRIPT_PATH"
echo "✓ Schema setup completed"
echo ""

# Verify setup
echo "Verifying database setup..."
PRODUCT_COUNT=$(PGPASSWORD=$DB_PASSWORD psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -t -c "SELECT COUNT(*) FROM productmanagement_dbo.products")
CATEGORY_COUNT=$(PGPASSWORD=$DB_PASSWORD psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -t -c "SELECT COUNT(*) FROM productmanagement_dbo.categories")
SUPPLIER_COUNT=$(PGPASSWORD=$DB_PASSWORD psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -t -c "SELECT COUNT(*) FROM productmanagement_dbo.suppliers")

echo "✓ Products: $PRODUCT_COUNT (expected: 19)"
echo "✓ Categories: $CATEGORY_COUNT (expected: 20)"
echo "✓ Suppliers: $SUPPLIER_COUNT (expected: 8)"
echo ""

# Update appsettings.json with actual password
echo "=========================================="
echo "IMPORTANT: Update Connection String"
echo "=========================================="
echo ""
echo "Please update appsettings.json with your actual database password:"
echo ""
echo "Connection string format:"
echo "Host=$DB_HOST;Port=$DB_PORT;Database=$DB_NAME;Username=$DB_USER;Password=YOUR_PASSWORD;Pooling=true;MinPoolSize=1;MaxPoolSize=20"
echo ""
echo "For security reasons, this script does not automatically update appsettings.json."
echo "Please edit it manually or use environment variables."
echo ""

# Build application
echo "Building application..."
cd "$(dirname "$0")"
if [ -f "AdoCore.csproj" ]; then
    dotnet build AdoCore.csproj
    if [ $? -eq 0 ]; then
        echo "✓ Application built successfully"
    else
        echo "⚠ Application build failed. Please check build.log for details."
    fi
else
    echo "⚠ AdoCore.csproj not found. Please build manually."
fi
echo ""

echo "=========================================="
echo "Database Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Update appsettings.json with your database password"
echo "2. Run integration tests to verify all operations"
echo "3. Review POSTGRESQL_DEPLOYMENT_GUIDE.md for additional configuration"
echo ""
echo "For troubleshooting, see POSTGRESQL_DEPLOYMENT_GUIDE.md"
