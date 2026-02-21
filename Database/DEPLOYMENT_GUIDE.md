# PostgreSQL Database Deployment Guide

## Overview
This guide provides instructions for deploying and testing the migrated PostgreSQL database for the AdoCore application.

## Prerequisites
- PostgreSQL 12 or higher installed and running
- Database administrator credentials
- Network access to the PostgreSQL server

## Database Schema Setup

### Required Tables
The application requires the following tables to be created:

1. **Products** - Main product information table
2. **ProductHistory** - Audit trail for product changes
3. **ProductStats** - Product statistics and metrics

### Schema Creation Scripts
Refer to the Scripts directory for PostgreSQL-compatible DDL scripts to create the required schema.

## Connection String Configuration

### Security Warning
⚠️ **CRITICAL**: The current connection strings in `appsettings.json` contain placeholder credentials that MUST be replaced before deployment.

### Current Configuration (Development Only)
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;Pooling=true",
    "ProdConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;Pooling=true"
  }
}
```

### Required Actions Before Production Deployment

1. **Replace Database Host**
   - Update `Host=localhost` with your actual PostgreSQL server hostname or IP address

2. **Replace Database Credentials**
   - Update `Username=postgres` with a dedicated application service account
   - Update `Password=postgres` with a strong, secure password
   - **NEVER** use default PostgreSQL superuser credentials in production

3. **Production Best Practices**
   - Use environment variables or secure configuration providers (Azure Key Vault, AWS Secrets Manager, etc.)
   - Implement principle of least privilege for database user permissions
   - Use connection pooling appropriately based on your workload
   - Enable SSL/TLS for database connections in production
   - Consider using managed identity or certificate-based authentication where possible

### Recommended Production Connection String Format
```
Host=your-db-server.example.com;Port=5432;Database=ProductManagement;Username=app_service_account;Password=<use-secrets-manager>;Pooling=true;SSL Mode=Require;Trust Server Certificate=false
```

## Verification Steps

### 1. Database Connection Test
After deploying the PostgreSQL database and updating connection strings:
```bash
dotnet run
```
The application should successfully connect to the PostgreSQL database.

### 2. CRUD Operations Testing
Test the following operations through the application CLI:
- **GetAll**: Retrieve all products
- **GetById**: Retrieve a specific product by ID
- **Insert**: Create a new product record
- **Update**: Modify an existing product
- **Delete**: Remove a product record

### 3. Transaction Testing
Test multi-statement transactions to verify atomicity:
- Perform operations that involve multiple SQL statements
- Verify rollback behavior on errors
- Confirm commit behavior on success

### 4. Integration Testing
Run the full test suite:
```bash
dotnet test
```

## Migration Completion Checklist

- [ ] PostgreSQL database instance deployed
- [ ] Database schema created (Products, ProductHistory, ProductStats tables)
- [ ] Connection strings updated with actual server hostname
- [ ] Secure credentials configured (not using default passwords)
- [ ] SSL/TLS enabled for production connections
- [ ] Connection test successful
- [ ] All CRUD operations verified
- [ ] Transaction atomicity verified
- [ ] Integration tests passing
- [ ] Npgsql package updated to secure version (8.0.8 or higher)

## Known Limitations

### Runtime Testing Not Yet Performed
The following exit criteria require a live PostgreSQL database and have not been verified:
- Exit Criterion 12: Application successfully connects to PostgreSQL database
- Exit Criterion 13: All database operations (SELECT, INSERT, UPDATE, DELETE) execute successfully
- Exit Criterion 14: Transaction blocks maintain atomicity
- Exit Criterion 15: Application passes all existing unit tests and integration tests

These verifications are blocked until a PostgreSQL database instance is available for testing.

## Support and Troubleshooting

### Common Issues

1. **Connection Timeout**
   - Verify PostgreSQL server is running
   - Check firewall rules and network connectivity
   - Verify connection string parameters

2. **Authentication Failed**
   - Confirm credentials are correct
   - Check PostgreSQL pg_hba.conf for authentication method
   - Verify user has appropriate database permissions

3. **Schema Not Found**
   - Ensure database schema is created before running application
   - Verify database name in connection string matches created database

4. **SSL/TLS Errors**
   - Configure SSL Mode parameter appropriately
   - Verify server certificate if using Trust Server Certificate=false

## Security Recommendations

1. **Credential Management**
   - Use Azure Key Vault, AWS Secrets Manager, or HashiCorp Vault
   - Never commit credentials to source control
   - Rotate credentials regularly

2. **Network Security**
   - Use private network connections where possible
   - Enable SSL/TLS for all connections
   - Implement IP whitelisting on database server

3. **Database Security**
   - Create dedicated service accounts with minimal required permissions
   - Enable PostgreSQL audit logging
   - Regularly update PostgreSQL server and apply security patches
   - Monitor for unusual connection patterns or query activity

## Next Steps

1. Deploy PostgreSQL database instance
2. Execute schema creation scripts
3. Update connection strings with secure credentials
4. Perform runtime verification tests
5. Execute full test suite
6. Monitor application performance and database connectivity
