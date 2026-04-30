# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other Windows-only framework monikers unless that is intentional.

### 2. Restore Dependencies
Run a full NuGet restore from the solution root to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm there are no warnings that may indicate runtime issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run the Test Suite
If the solution contains test projects, execute all tests to verify behavioral correctness after the migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate subtle behavioral differences between .NET Framework and cross-platform .NET.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer or review the build output for `CA1416` platform compatibility warnings. These indicate calls to Windows-only APIs (e.g., registry access, certain `System.Drawing` features) that may fail on Linux or macOS.

You can enable the analyzer explicitly in your `.csproj` if it is not already active:

```xml
<PropertyGroup>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <AnalysisMode>All</AnalysisMode>
</PropertyGroup>
```

### 6. Validate Runtime Behavior
Run the application on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement. Pay particular attention to:

- File path separators (`\` vs `/`)
- Case sensitivity in file system operations
- Environment variable differences
- Culture and encoding defaults

### 7. Review `AdoCore` Project Specifically
Since `AdoCore` is the most independent project in the solution (listed last), confirm that its data access logic is compatible with the target database drivers under cross-platform .NET. If it uses `System.Data.OleDb` or similar Windows-only providers, those will need to be replaced with cross-platform alternatives such as `Microsoft.Data.SqlClient`.

### 8. Publish a Test Build
Produce a self-contained or framework-dependent publish output and verify it runs correctly in the target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Adjust the `--runtime` identifier to match your deployment target.