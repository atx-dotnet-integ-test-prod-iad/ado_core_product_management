# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element targets the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other Windows-only framework monikers unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm the absence of errors is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that may indicate compatibility concerns even if they do not block the build.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review test results carefully, paying attention to any tests that were previously passing and are now failing.

### 5. Check for Windows-Specific API Usage
Even if the project compiles, it may contain APIs that are only supported on Windows. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Look for warnings prefixed with `CA1416` which indicate platform-specific API calls that may fail on Linux or macOS.

### 6. Run on Target Platforms
If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to catch any runtime-only issues such as:

- File path separator differences (`\` vs `/`)
- Case-sensitive file system behavior on Linux
- Missing platform-specific dependencies

### 7. Review `AdoCore.csproj` Specifically
Since `AdoCore.csproj` is listed as the most independent project in the solution, validate it first in isolation:

```bash
dotnet build src/AdoCore/AdoCore.csproj --configuration Release
dotnet test src/AdoCore/AdoCore.csproj --configuration Release
```

Confirm its output assemblies are being correctly referenced by dependent projects.

### 8. Publish a Release Build
Once validation is complete, produce a published output to confirm the final deployable artifact is generated correctly:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to confirm all expected assemblies, configuration files, and assets are present.