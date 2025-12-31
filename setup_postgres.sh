#!/bin/bash

# PostgreSQL Database Setup and Validation Script
# This script automates the setup of PostgreSQL database for the migrated AdoCore application

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-postgres}"
POSTGRES_DB="${POSTGRES_DB:-ProductManagement}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_SCRIPT="${SCRIPT_DIR}/Database/Scripts/01_PostgreSQL_Setup.sql"

# Functions
print_header() {
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check if psql is installed
    if command -v psql &> /dev/null; then
        print_success "psql (PostgreSQL client) is installed"
        PSQL_VERSION=$(psql --version | awk '{print $3}')
        print_info "Version: $PSQL_VERSION"
    else
        print_error "psql not found. Please install PostgreSQL client tools."
        exit 1
    fi
    
    # Check if dotnet is installed
    if command -v dotnet &> /dev/null; then
        print_success "dotnet SDK is installed"
        DOTNET_VERSION=$(dotnet --version)
        print_info "Version: $DOTNET_VERSION"
    else
        print_error "dotnet SDK not found. Please install .NET SDK."
        exit 1
    fi
    
    # Check if SQL script exists
    if [ -f "$SQL_SCRIPT" ]; then
        print_success "PostgreSQL setup script found"
    else
        print_error "Setup script not found at: $SQL_SCRIPT"
        exit 1
    fi
    
    echo ""
}

check_postgres_connection() {
    print_header "Checking PostgreSQL Connection"
    
    if PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d postgres -c '\q' 2>/dev/null; then
        print_success "Connected to PostgreSQL at $POSTGRES_HOST:$POSTGRES_PORT"
        return 0
    else
        print_error "Cannot connect to PostgreSQL at $POSTGRES_HOST:$POSTGRES_PORT"
        print_info "Please ensure PostgreSQL is running and credentials are correct"
        return 1
    fi
    
    echo ""
}

create_database() {
    print_header "Creating Database"
    
    # Check if database exists
    DB_EXISTS=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$POSTGRES_DB'")
    
    if [ "$DB_EXISTS" = "1" ]; then
        print_info "Database '$POSTGRES_DB' already exists"
        read -p "Do you want to drop and recreate it? (yes/no): " RECREATE
        if [ "$RECREATE" = "yes" ]; then
            print_info "Dropping existing database..."
            PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d postgres -c "DROP DATABASE IF EXISTS \"$POSTGRES_DB\";"
            print_success "Database dropped"
        else
            print_info "Using existing database"
            echo ""
            return 0
        fi
    fi
    
    # Create database
    print_info "Creating database '$POSTGRES_DB'..."
    PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d postgres -c "CREATE DATABASE \"$POSTGRES_DB\";"
    print_success "Database created successfully"
    
    echo ""
}

setup_schema() {
    print_header "Setting Up Database Schema"
    
    print_info "Running setup script..."
    if PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -f "$SQL_SCRIPT" > /dev/null 2>&1; then
        print_success "Schema setup completed"
    else
        print_error "Schema setup failed"
        print_info "Check $SQL_SCRIPT for errors"
        exit 1
    fi
    
    echo ""
}

verify_schema() {
    print_header "Verifying Database Schema"
    
    # Check schema exists
    SCHEMA_EXISTS=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -tAc "SELECT 1 FROM information_schema.schemata WHERE schema_name='productmanagement_dbo'")
    if [ "$SCHEMA_EXISTS" = "1" ]; then
        print_success "Schema 'productmanagement_dbo' exists"
    else
        print_error "Schema 'productmanagement_dbo' not found"
        exit 1
    fi
    
    # Check tables
    TABLES=("categories" "suppliers" "products" "producthistory" "productstats")
    for TABLE in "${TABLES[@]}"; do
        TABLE_EXISTS=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -tAc "SELECT 1 FROM information_schema.tables WHERE table_schema='productmanagement_dbo' AND table_name='$TABLE'")
        if [ "$TABLE_EXISTS" = "1" ]; then
            print_success "Table '$TABLE' exists"
        else
            print_error "Table '$TABLE' not found"
            exit 1
        fi
    done
    
    # Check data
    PRODUCT_COUNT=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -tAc "SELECT COUNT(*) FROM productmanagement_dbo.products")
    if [ "$PRODUCT_COUNT" -gt 0 ]; then
        print_success "Sample data loaded: $PRODUCT_COUNT products"
    else
        print_error "No sample data found"
        exit 1
    fi
    
    echo ""
}

build_application() {
    print_header "Building .NET Application"
    
    cd "$SCRIPT_DIR"
    
    print_info "Restoring NuGet packages..."
    if dotnet restore > /dev/null 2>&1; then
        print_success "Packages restored"
    else
        print_error "Package restore failed"
        exit 1
    fi
    
    print_info "Building application..."
    if dotnet build > /dev/null 2>&1; then
        print_success "Build succeeded"
    else
        print_error "Build failed"
        exit 1
    fi
    
    echo ""
}

test_connectivity() {
    print_header "Testing Application Connectivity"
    
    cd "$SCRIPT_DIR"
    
    print_info "Attempting to list products..."
    OUTPUT=$(dotnet run -- list 2>&1)
    EXIT_CODE=$?
    
    if [ $EXIT_CODE -eq 0 ]; then
        print_success "Application connected to database successfully"
        print_info "Sample output:"
        echo "$OUTPUT" | head -10
        if [ $(echo "$OUTPUT" | wc -l) -gt 10 ]; then
            echo "... (output truncated)"
        fi
    else
        print_error "Application failed to connect to database"
        print_info "Error output:"
        echo "$OUTPUT"
        exit 1
    fi
    
    echo ""
}

run_crud_tests() {
    print_header "Running CRUD Operation Tests"
    
    cd "$SCRIPT_DIR"
    
    # Test INSERT
    print_info "Testing INSERT operation..."
    INSERT_OUTPUT=$(dotnet run -- add "Test Product" 99.99 50 "Test description" 2>&1)
    if echo "$INSERT_OUTPUT" | grep -q "successfully\|created\|added"; then
        print_success "INSERT operation successful"
    else
        print_error "INSERT operation failed"
        echo "$INSERT_OUTPUT"
    fi
    
    # Test UPDATE
    print_info "Testing UPDATE operation..."
    UPDATE_OUTPUT=$(dotnet run -- update 1 "Updated Product" 89.99 45 "Updated description" 2>&1)
    if echo "$UPDATE_OUTPUT" | grep -q "successfully\|updated"; then
        print_success "UPDATE operation successful"
    else
        print_error "UPDATE operation failed"
        echo "$UPDATE_OUTPUT"
    fi
    
    # Test SELECT by ID
    print_info "Testing SELECT by ID operation..."
    GET_OUTPUT=$(dotnet run -- get 1 2>&1)
    if echo "$GET_OUTPUT" | grep -q "ProductId\|Product"; then
        print_success "SELECT by ID operation successful"
    else
        print_error "SELECT by ID operation failed"
        echo "$GET_OUTPUT"
    fi
    
    echo ""
}

print_summary() {
    print_header "Setup Complete!"
    
    echo -e "${GREEN}Database Information:${NC}"
    echo "  Host: $POSTGRES_HOST"
    echo "  Port: $POSTGRES_PORT"
    echo "  Database: $POSTGRES_DB"
    echo "  Schema: productmanagement_dbo"
    echo ""
    
    echo -e "${GREEN}Connection String:${NC}"
    echo "  Host=$POSTGRES_HOST;Port=$POSTGRES_PORT;Database=$POSTGRES_DB;Username=$POSTGRES_USER;Password=***"
    echo ""
    
    echo -e "${GREEN}Next Steps:${NC}"
    echo "  1. Run the application:"
    echo "     cd $SCRIPT_DIR"
    echo "     dotnet run"
    echo ""
    echo "  2. Run CLI commands:"
    echo "     dotnet run -- list"
    echo "     dotnet run -- get 1"
    echo ""
    echo "  3. See POSTGRESQL_DEPLOYMENT_GUIDE.md for comprehensive testing"
    echo ""
}

# Main execution
main() {
    echo -e "${GREEN}PostgreSQL Setup and Validation Script${NC}"
    echo -e "${GREEN}for AdoCore Application Migration${NC}"
    echo ""
    
    # Run checks and setup
    check_prerequisites
    
    if ! check_postgres_connection; then
        print_info "Would you like to try with Docker? (yes/no): "
        read USE_DOCKER
        if [ "$USE_DOCKER" = "yes" ]; then
            print_info "Starting PostgreSQL in Docker..."
            docker run --name postgres-adocore \
                -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
                -e POSTGRES_DB=$POSTGRES_DB \
                -p $POSTGRES_PORT:5432 \
                -d postgres:15
            print_info "Waiting for PostgreSQL to start..."
            sleep 5
            if ! check_postgres_connection; then
                print_error "Failed to start PostgreSQL in Docker"
                exit 1
            fi
        else
            exit 1
        fi
    fi
    
    create_database
    setup_schema
    verify_schema
    build_application
    test_connectivity
    run_crud_tests
    print_summary
}

# Run main function
main
