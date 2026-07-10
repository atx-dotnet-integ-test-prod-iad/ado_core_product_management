# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other outdated monikers unless intentionally targeting multiple frameworks.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts.

### 3. Build the Solution
Perform a clean build to confirm there are no warnings that could indicate runtime issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify functional correctness:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failed or skipped tests that may indicate behavioral regressions introduced during the migration.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any remaining Windows-specific API calls (e.g., registry access, `System.Windows.Forms`, COM interop) that may compile successfully but fail at runtime on non-Windows platforms.

You can add the analyzer via:

```bash
dotnet add package Microsoft.DotNet.ApiCompat
```

### 6. Review `App.config` / `Web.config` Migrations
If the original project used `App.config` or `Web.config`, confirm that settings have been properly migrated to `appsettings.json` or environment-based configuration using `Microsoft.Extensions.Configuration`.

### 7. Validate Runtime Behavior
Run the application on each target platform (Windows, Linux, macOS) to confirm there are no platform-specific runtime exceptions. Pay particular attention to:

- File path separators (`/` vs `\`)
- Case-sensitive file system differences on Linux
- Any P/Invoke or native library dependencies

### 8. Review Output Artifacts
After a successful Release build, inspect the output directory:

```bash
dotnet publish --configuration Release --output ./publish
```

Confirm that all expected assemblies, configuration files, and static assets are present in the publish output.