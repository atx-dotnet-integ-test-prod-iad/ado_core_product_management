# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other legacy/EOL targets unless intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages, missing packages, or version conflicts.

### 3. Build the Solution
Perform a full solution build to confirm there are no warnings that may indicate hidden issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release
```

Review test results and investigate any failures that may have been introduced during the transformation.

### 5. Check for Platform-Specific API Usage
Use the .NET Compatibility Analyzer or review code manually for any APIs that may have been available in .NET Framework but behave differently or are unavailable in cross-platform .NET. Common areas to check include:

- `System.Windows.Forms` or `System.Web` references (these are Windows-only or removed)
- Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage
- `BinaryFormatter` (deprecated and disabled by default in modern .NET)

Run the following to surface compatibility issues:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

### 6. Verify Configuration and App Settings
If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated appropriately to `appsettings.json` or environment-based configuration using `Microsoft.Extensions.Configuration`.

### 7. Validate Runtime Behavior
Run the application manually and exercise its primary workflows. Compare the output and behavior against the original .NET Framework version to confirm functional equivalence.

### 8. Review Output Artifacts
Check that the published output is structured as expected:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to confirm all required files, assemblies, and assets are present.