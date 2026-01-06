# Connection String Migration Guide

## Overview
This document provides guidance for migrating SQL Server connection strings to PostgreSQL format as part of the Microsoft SQL Server to PostgreSQL migration for the AdoCore application.

## Connection String Transformations

### Development Connection
**Original (SQL Server):**
```
Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True
```

**Migrated (PostgreSQL):**
```
Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres;Port=5432;Pooling=true
```

### Production Connection
**Original (SQL Server):**
```
Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True
```

**Migrated (PostgreSQL):**
```
Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres;Port=5432;Pooling=true
```

## Parameter Mapping

| SQL Server Parameter | PostgreSQL Equivalent | Notes |
|---------------------|----------------------|-------|
| Server | Host | Database server hostname or IP |
| Database | Database | Database name (unchanged) |
| Trusted_Connection | Username/Password | PostgreSQL requires explicit credentials |
| MultipleActiveResultSets | (removed) | Not applicable to PostgreSQL |
| TrustServerCertificate | (removed) | SSL configuration handled differently in PostgreSQL |
| (new) | Port | PostgreSQL default port is 5432 |
| (new) | Pooling | Connection pooling (recommended for performance) |

## Deployment Considerations

### Security
- **CRITICAL**: Replace placeholder password 'postgres' with secure credentials before deployment
- Store production credentials in secure configuration (Azure Key Vault, AWS Secrets Manager, etc.)
- Consider using certificate-based authentication for production environments
- Use encrypted connections (SSL/TLS) in production

### Connection Pool Settings
The migrated connection strings use basic pooling. For production, consider:
- `Minimum Pool Size`: Start with 0 (default)
- `Maximum Pool Size`: Adjust based on load (default: 100)
- `Connection Lifetime`: Set timeout for connection recycling
- `Connection Idle Lifetime`: Close idle connections

### Port Configuration
- Default PostgreSQL port: 5432
- Ensure firewall rules allow application to database connectivity
- Update network security groups/ACLs as needed

### Multi-Environment Configuration
The current configuration stores credentials directly in appsettings.json. Consider:
1. User Secrets for local development
2. Environment Variables for containers
3. Secret Management Services for production

## Testing Checklist
- [ ] Verify connection successful from application host to database
- [ ] Test database connectivity with updated connection strings
- [ ] Validate authentication credentials
- [ ] Confirm firewall/network rules allow traffic on port 5432
- [ ] Test connection pooling behavior under load
- [ ] Verify SSL/TLS configuration if required

## Rollback Plan
If rollback is needed:
1. Restore original appsettings.json from version control
2. Update AdoCore.csproj to use Microsoft.Data.SqlClient
3. Revert code changes to use SQL Server types
4. Redeploy application

## Additional Resources
- Npgsql Connection String Parameters: https://www.npgsql.org/doc/connection-string-parameters.html
- PostgreSQL Authentication Methods: https://www.postgresql.org/docs/current/auth-methods.html
