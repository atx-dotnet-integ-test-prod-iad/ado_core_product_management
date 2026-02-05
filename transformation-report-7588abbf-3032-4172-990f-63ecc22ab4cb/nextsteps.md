# Next Steps

## Overview
The transformation appears to have completed successfully with no build errors reported in the solution. This indicates that the project structure, dependencies, and code have been properly migrated to cross-platform .NET.

## Validation Steps

### 1. Verify Project Configuration
- Open each `.csproj` file and confirm the target framework is set appropriately (e.g., `net6.0`, `net7.0`, or `net8.0`)
- Verify that all package references have been updated to versions compatible with the target framework
- Check that any legacy `packages.config` files have been removed and dependencies are now managed via `PackageReference`

### 2. Build Verification
```bash
# Clean the solution
dotnet clean

# Restore dependencies
dotnet restore

# Build in Release configuration
dotnet build -c Release

# Verify no warnings that could indicate runtime issues
dotnet build --no-incremental /warnaserror
```

### 3. Run Unit Tests
```bash
# Execute all tests in the solution
dotnet test

# Run tests with detailed output
dotnet test --logger "console;verbosity=detailed"

# Generate code coverage if applicable
dotnet test --collect:"XPlat Code Coverage"
```

### 4. Runtime Validation

#### Check for Platform-Specific Code
- Review any P/Invoke declarations or native interop code
- Verify file path handling uses `Path.Combine()` and not hardcoded separators
- Confirm registry access or Windows-specific APIs have cross-platform alternatives or guards

#### Test on Target Platforms
- Run the application on Windows to ensure backward compatibility
- Test on Linux (Ubuntu/Debian recommended)
- Test on macOS if applicable to your deployment targets

### 5. Dependency Audit
```bash
# List all package dependencies
dotnet list package

# Check for deprecated packages
dotnet list package --deprecated

# Check for packages with known vulnerabilities
dotnet list package --vulnerable
```

### 6. Configuration Files
- Review `app.config` or `web.config` files - these may need conversion to `appsettings.json`
- Verify connection strings and environment-specific settings are externalized
- Confirm that configuration providers are compatible with cross-platform .NET

### 7. Data Access Layer
If the project uses ADO (as suggested by `AdoCore.csproj`):
- Test all database connections on different platforms
- Verify SQL queries don't contain platform-specific syntax
- Confirm connection string formats are correct for the target framework
- Test transaction handling and connection pooling behavior

### 8. Performance Testing
- Run performance benchmarks comparing the migrated version to the legacy version
- Monitor memory usage and garbage collection behavior
- Profile startup time and resource utilization

## Deployment Preparation

### 1. Create Deployment Artifacts
```bash
# Publish self-contained for specific runtime
dotnet publish -c Release -r win-x64 --self-contained true

# Publish framework-dependent (smaller size)
dotnet publish -c Release
```

### 2. Runtime Identifier (RID) Selection
Choose appropriate RIDs for your target platforms:
- `win-x64`, `win-x86`, `win-arm64` for Windows
- `linux-x64`, `linux-arm64` for Linux
- `osx-x64`, `osx-arm64` for macOS

### 3. Deployment Verification Checklist
- [ ] All configuration files are included in publish output
- [ ] Required runtime dependencies are present
- [ ] File permissions are set correctly (Linux/macOS)
- [ ] Environment variables are documented
- [ ] Database migration scripts are prepared (if applicable)

### 4. Documentation Updates
- Update deployment documentation with new framework requirements
- Document any breaking changes from the legacy version
- Create platform-specific deployment guides
- Update system requirements (minimum OS versions, runtime prerequisites)

## Monitoring Post-Deployment

### 1. Logging
- Verify logging works correctly on all platforms
- Ensure log file paths are platform-agnostic
- Test log rotation and retention policies

### 2. Error Tracking
- Monitor application logs for any runtime exceptions
- Track performance metrics compared to baseline
- Watch for platform-specific issues in production

### 3. Rollback Plan
- Maintain the legacy version in a stable state
- Document rollback procedures
- Keep deployment scripts for quick reversion if needed

## Additional Considerations

- If using third-party libraries, verify they support your target framework
- Review any COM interop usage - this is Windows-only and requires alternatives
- Check for hardcoded Windows paths (e.g., `C:\`, backslashes)
- Validate that any file I/O operations handle case-sensitive file systems (Linux/macOS)
- Test application behavior with different culture settings and time zones