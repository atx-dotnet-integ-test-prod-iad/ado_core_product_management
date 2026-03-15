# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other legacy/end-of-life monikers unless intentionally retained.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding.

### 4. Check for Removed or Changed APIs
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.ApiCompat` tooling to identify any APIs that were available in the legacy framework but have been removed or changed in the target framework:

```bash
dotnet tool install -g dotnet-apicompat
```

Pay particular attention to areas such as:
- `System.Web` usage (not available in cross-platform .NET)
- Windows-specific APIs (e.g., registry, WCF server-side, certain cryptography providers)
- Reflection APIs that changed behavior

### 5. Review NuGet Package Compatibility
Open the `.csproj` files and review all `<PackageReference>` entries. For each package, confirm the version in use supports the new target framework by checking [nuget.org](https://www.nuget.org). Replace or update any packages that only supported .NET Framework.

### 6. Validate Runtime Behavior
Run the application locally and exercise the primary workflows manually or through integration tests. Pay attention to:
- Configuration loading (e.g., `app.config` vs `appsettings.json`)
- File path handling (ensure no hardcoded Windows-style paths)
- Any platform-specific features that may behave differently on Linux or macOS

### 7. Review `AdoCore` Project Specifically
Since `AdoCore` is the most independent project in the solution (and therefore foundational), confirm the following:
- All ADO.NET data provider packages used (e.g., `System.Data.SqlClient` vs `Microsoft.Data.SqlClient`) are updated to their cross-platform equivalents.
- Connection string handling and configuration sources are compatible with the new hosting model.

### 8. Publish a Release Build
Once validation is complete, produce a published output to confirm the deployment artifact is correct:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the contents of the `./publish` directory and confirm all expected assemblies and configuration files are present.