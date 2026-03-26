# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless a multi-targeting scenario is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm there are no warnings that may indicate compatibility issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility analyzers (`CA1416`, etc.).

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failed or skipped tests that may indicate behavioral regressions introduced during transformation.

### 5. Check for Platform-Specific API Usage
Run the .NET Compatibility Analyzer by ensuring the following property is set in each `.csproj`:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

Rebuild and review diagnostics for any APIs flagged as Windows-only or otherwise platform-restricted, particularly if the goal is to run on Linux or macOS.

### 6. Validate Configuration and App Settings
If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables, and that `ConfigurationManager` calls have been replaced with the `Microsoft.Extensions.Configuration` equivalents where applicable.

### 7. Verify Output Artifacts
Publish the project and inspect the output directory to confirm all expected files are present:

```bash
dotnet publish --configuration Release --output ./publish
```

Check that no required native binaries, resource files, or content files are missing from the publish output.

### 8. Smoke Test the Application
Run the published output directly to confirm the application starts and executes its core functionality without runtime exceptions:

```bash
dotnet ./publish/AdoCore.dll
```

Adjust the entry point as appropriate for the project type (console, web, library, etc.).