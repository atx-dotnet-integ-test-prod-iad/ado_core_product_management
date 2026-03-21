# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless intentionally targeting multiple frameworks.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Run a full solution build to confirm the no-error state is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check both `Debug` and `Release` configurations if your project has configuration-specific code paths.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any test failures or skipped tests that may indicate behavioral differences introduced by the migration.

### 5. Audit Removed Windows-Specific APIs
Search the codebase for any APIs that were available in .NET Framework but have been removed or behave differently in cross-platform .NET. Common areas to check include:

- `System.Web` usages
- `System.Runtime.Remoting`
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain.CreateDomain`
- `BinaryFormatter` (deprecated and disabled by default in .NET 5+)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to surface remaining compatibility issues.

### 6. Verify Configuration System
If the project previously used `System.Configuration` (`app.config` / `web.config`), confirm it has been migrated to the appropriate .NET configuration model, such as `Microsoft.Extensions.Configuration` with `appsettings.json`.

### 7. Check for Platform-Specific Runtime Behavior
Run the application on each target operating system (Windows, Linux, macOS) if cross-platform support is a requirement. Pay particular attention to:

- File path separators
- Case sensitivity in file system operations
- Environment variable handling
- Culture and locale differences

### 8. Review Output Artifacts
Confirm the build output directory contains the expected assemblies and that no required assets (e.g., native libraries, resource files) are missing from the published output:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` folder to verify all runtime dependencies are present.

## Deployment

Once all validation steps pass without errors or unexpected warnings, the application can be deployed using the published output produced in Step 8. Distribute the contents of the `./publish` folder to the target environment and execute the entry-point assembly:

```bash
dotnet AdoCore.dll
```

Or, if published as a self-contained executable:

```bash
./AdoCore
```