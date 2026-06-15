# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other legacy/end-of-life monikers unless intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm there are no hidden warnings or errors:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings (CA1416).

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failed or skipped tests and investigate the cause of each.

### 5. Check for Removed or Changed APIs
Use the .NET Upgrade Assistant compatibility analyzer or review the [.NET API compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) to confirm that any APIs used from the legacy project are still available and behave the same way on cross-platform .NET.

Pay particular attention to:
- `System.Web` usages (not available on .NET Core/.NET 5+)
- Windows-specific APIs (e.g., registry, WCF server-side, Windows Forms if targeting non-Windows)
- `AppDomain`, `BinaryFormatter`, and other APIs with breaking changes

### 6. Run the Application and Perform Smoke Testing
Start the application and manually verify that core functionality works as expected:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Test the primary workflows that were exercised in the legacy version to confirm behavioral parity.

### 7. Review Runtime Configuration
Check `appsettings.json`, `app.config`, or any environment-specific configuration files to ensure connection strings, endpoints, and feature flags are correctly set for the target environment.

### 8. Validate Platform-Specific Behavior
If the application is intended to run on Linux or macOS in addition to Windows, test it explicitly on those platforms. File path separators, case sensitivity, and certain default encodings differ between platforms and can cause subtle runtime issues.