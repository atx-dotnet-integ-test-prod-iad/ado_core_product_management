# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless a multi-targeting scenario is intentional.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if they do not produce build errors.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding.

### 4. Check for Removed or Changed APIs
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.ApiCompat` tooling to identify any APIs that were available in .NET Framework but behave differently or are absent in cross-platform .NET:

```bash
dotnet tool install -g dotnet-apicompat
```

Pay particular attention to:
- `System.Web` usages (not available in cross-platform .NET)
- Windows-specific APIs (e.g., registry access, WCF server-side, Windows Forms if targeting non-Windows)
- Reflection behaviors that differ between runtimes

### 5. Review NuGet Package Compatibility
Open the `.csproj` files and inspect each `<PackageReference>`. For any package that has not been updated recently, verify it supports the target framework by checking [nuget.org](https://www.nuget.org). Replace or update packages that only support .NET Framework.

### 6. Validate Runtime Behavior
Run the application manually or through its entry point and exercise the primary workflows. Look for:
- `PlatformNotSupportedException` at runtime
- Missing configuration files (e.g., `app.config` behavior differs; prefer `appsettings.json` with `Microsoft.Extensions.Configuration`)
- File path separator issues (`\` vs `/`) if the application constructs paths manually — use `Path.Combine` or `Path.DirectorySeparatorChar` instead

### 7. Review `AdoCore.csproj` Specifically
Since `AdoCore` is listed as the most independent project in the solution, confirm the following:
- Any ADO.NET-related dependencies (e.g., `System.Data.SqlClient`) have been migrated to `Microsoft.Data.SqlClient` where applicable, as the latter is the actively maintained cross-platform package
- Connection string handling and provider factory patterns are compatible with the new runtime

```xml
<PackageReference Include="Microsoft.Data.SqlClient" Version="5.2.0" />
```

### 8. Publish a Release Build
Once validation is complete, produce a published output to confirm the final deployable artifact builds correctly:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` folder to ensure all expected assemblies and assets are present.