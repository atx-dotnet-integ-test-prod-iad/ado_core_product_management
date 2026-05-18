# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net48`, `netcoreapp`, or other legacy monikers unless intentionally targeting multiple frameworks.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved references.

### 3. Build the Solution
Perform a clean build to confirm no errors surface in a fresh build environment:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings (CA1416).

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify functional correctness after the transformation:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failed or skipped tests that may indicate behavioral regressions.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer to identify any remaining platform-specific API calls that could break on non-Windows systems:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to diagnostics prefixed with `CA1416` (platform compatibility).

### 6. Review `AdoCore` Project Specifically
Since `AdoCore.csproj` is the most independent project in the solution (and therefore foundational), manually verify the following within it:

- Any ADO.NET or database connection logic that previously relied on Windows-specific drivers (e.g., OLE DB, ODBC) has been replaced with cross-platform compatible providers.
- Connection strings and configuration values are sourced from `appsettings.json` or environment variables rather than hardcoded or sourced from the Windows registry.
- Any use of `System.Data.OleDb` has been replaced with a supported cross-platform alternative such as `Microsoft.Data.SqlClient`.

### 7. Validate Runtime Behavior
Run the application on the target platform (Linux or macOS if cross-platform is the goal) and confirm core workflows execute without exceptions:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

### 8. Review Output Artifacts
Publish the solution and inspect the output directory to confirm all expected assemblies, configuration files, and assets are present:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the `./publish` directory contains no unexpected Windows-only binaries (`.dll` files tied to COM or GAC).