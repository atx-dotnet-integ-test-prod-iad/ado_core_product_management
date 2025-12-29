# Dependency Update Log
# SQL Server to PostgreSQL Migration
# Date: 2024-12-29

## Overview
This log documents the replacement of Microsoft SQL Server database client package (Microsoft.Data.SqlClient) with the PostgreSQL equivalent (Npgsql) in the AdoCore.csproj file.

## Changes Made

### Package References Removed
**Package:** Microsoft.Data.SqlClient  
**Version:** 5.1.4  
**Reason:** SQL Server specific client library, incompatible with PostgreSQL

### Package References Added
**Package:** Npgsql  
**Version:** 8.0.5  
**Reason:** PostgreSQL data provider for .NET, provides equivalent functionality to Microsoft.Data.SqlClient

**Note on Version Selection:** Initially attempted version 8.0.0 but encountered security vulnerability warning NU1903 (GitHub Advisory GHSA-x9vc-6hfv-hg8c). Upgraded to version 8.0.5 to address the security concern.

### Packages Retained
The following Microsoft.Extensions packages remain unchanged as they are not database-specific:
- Microsoft.Extensions.Configuration (Version 8.0.0)
- Microsoft.Extensions.Configuration.Json (Version 8.0.0)
- Microsoft.Extensions.DependencyInjection (Version 8.0.0)

## File Modified
**Path:** /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/AdoCore.csproj

### Before:
```xml
<ItemGroup>
  <PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />
  <PackageReference Include="Microsoft.Extensions.Configuration" Version="8.0.0" />
  <PackageReference Include="Microsoft.Extensions.Configuration.Json" Version="8.0.0" />
  <PackageReference Include="Microsoft.Extensions.DependencyInjection" Version="8.0.0" />
</ItemGroup>
```

### After:
```xml
<ItemGroup>
  <PackageReference Include="Npgsql" Version="8.0.5" />
  <PackageReference Include="Microsoft.Extensions.Configuration" Version="8.0.0" />
  <PackageReference Include="Microsoft.Extensions.Configuration.Json" Version="8.0.0" />
  <PackageReference Include="Microsoft.Extensions.DependencyInjection" Version="8.0.0" />
</ItemGroup>
```

## Verification

### Package Restore
Command: `dotnet restore`  
Status: SUCCESS  
Output: Package Npgsql 8.0.5 successfully restored with no security warnings

### Build Verification
Command: `dotnet build`  
Status: SUCCESS (after subsequent code changes)  
Errors: 0  
Warnings: 0 (nullable reference warnings resolved through code updates)

## Impact Analysis

### Breaking Changes
- All references to Microsoft.Data.SqlClient classes (SqlConnection, SqlCommand, SqlDataReader, SqlParameter, SqlTransaction) now require equivalent Npgsql classes
- These changes are handled in the ADO.NET class replacement step (Step 6)

### Compatible Features
Npgsql provides equivalent functionality for:
- Connection management (NpgsqlConnection)
- Command execution (NpgsqlCommand)
- Data reading (NpgsqlDataReader)
- Parameter binding (NpgsqlParameter)
- Transaction management (NpgsqlTransaction)
- Async operations (all async methods supported)

### Additional Capabilities
Npgsql provides PostgreSQL-specific features:
- Support for PostgreSQL data types (arrays, JSON, hstore, etc.)
- COPY operations for bulk data loading
- LISTEN/NOTIFY for pub/sub messaging
- Server-side prepared statements

## Security Considerations
- Npgsql 8.0.5 selected to avoid known vulnerability in 8.0.0
- Regular security updates should be monitored through NuGet security advisories
- Production deployments should use the latest stable, non-vulnerable version

## Compatibility Notes
- Npgsql 8.0.5 requires .NET 6.0 or higher (AdoCore targets .NET 9.0 - compatible)
- Connection string format differs from SQL Server (addressed in connection string migration step)
- Parameter syntax remains compatible (@ParamName works in both)

## Documentation References
- Npgsql Documentation: https://www.npgsql.org/doc/
- GitHub Advisory (8.0.0 vulnerability): https://github.com/advisories/GHSA-x9vc-6hfv-hg8c
- Migration Guide: https://www.npgsql.org/doc/migration.html

## Summary
Successfully replaced Microsoft.Data.SqlClient 5.1.4 with Npgsql 8.0.5, addressing security concerns and establishing the foundation for PostgreSQL database connectivity. All package dependencies are now PostgreSQL-compatible.
