# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Run a full solution build to confirm the no-error state is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check both `Debug` and `Release` configurations if the project has configuration-specific code paths.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any test failures that may indicate behavioral differences introduced by the migration.

### 5. Verify Platform-Specific APIs
Search the codebase for any APIs that were available in .NET Framework but have been removed or altered in cross-platform .NET. Common areas to check include:

- `System.Web` usage
- `System.Drawing` (requires the `System.Drawing.Common` package on non-Windows platforms and has restrictions)
- Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) client/server code
- `AppDomain` members that are no longer supported

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.ApiCompat` tool to surface any remaining compatibility issues.

### 6. Run on Target Platforms
If cross-platform support is a goal, execute the application on each intended operating system (Windows, Linux, macOS) to catch any runtime issues that do not surface at compile time:

```bash
dotnet run --configuration Release
```

Pay particular attention to file path separators, line endings, and any P/Invoke or native interop calls.

### 7. Review Output Artifacts
Confirm the build output is placed in the expected location and that all required assets (configuration files, static resources, etc.) are copied correctly:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to ensure all necessary files are present before deployment.

### 8. Check for Deprecated NuGet Packages
Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update packages where newer versions offer better .NET compatibility or security fixes.