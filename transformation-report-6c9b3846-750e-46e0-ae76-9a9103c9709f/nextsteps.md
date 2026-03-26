# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other outdated monikers unless intentionally targeting multiple frameworks.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding.

### 4. Check for Removed or Changed APIs
Use the .NET Upgrade Assistant compatibility analyzer or review the [.NET API compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) to identify any APIs that were available in .NET Framework but have been removed or altered in cross-platform .NET. Pay particular attention to:

- `System.Web` usages (not available in cross-platform .NET)
- Windows-specific APIs (e.g., registry access, WCF server-side, Windows Forms if targeting non-Windows)
- Reflection behaviors that differ between runtimes

### 5. Review NuGet Package Compatibility
Open the `.csproj` files and inspect all `<PackageReference>` entries. For each package, verify that the version referenced supports the target framework by checking [NuGet.org](https://www.nuget.org). Replace any packages that only support .NET Framework with their cross-platform equivalents.

### 6. Validate Platform-Specific Behavior at Runtime
Build and run the application on each intended target platform (Windows, Linux, macOS) to surface any platform-specific runtime exceptions that would not appear at compile time:

```bash
dotnet run --configuration Release
```

### 7. Review Configuration and File Paths
Inspect any hardcoded file paths, configuration file references (`app.config`, `web.config`), or environment-specific settings. In cross-platform .NET:

- `app.config` is replaced by `appsettings.json` in most project types.
- File path separators differ between Windows and Unix systems; use `Path.Combine` or `Path.DirectorySeparatorChar` rather than hardcoded backslashes.

### 8. Publish a Release Build
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value, such as `win-x64`, `linux-x64`, or `osx-x64`. Review the publish output directory to confirm all required assets are present.