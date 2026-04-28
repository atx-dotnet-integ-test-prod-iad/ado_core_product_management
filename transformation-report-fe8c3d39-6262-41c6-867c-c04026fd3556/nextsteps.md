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

Check the output for any warnings that may indicate compatibility issues even if the build succeeds.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review test results carefully, paying attention to any tests that were previously passing under the legacy framework.

### 5. Check for Windows-Specific API Usage
Even with a successful build, runtime failures can occur if the code uses Windows-specific APIs (e.g., registry access, `System.Drawing`, COM interop). Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Review any analyzer warnings that appear after adding this package and rebuilding.

### 6. Review `App.config` / `Web.config` Migrations
If the original project used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or another supported configuration mechanism, as these legacy config files have limited support in cross-platform .NET.

### 7. Validate Runtime Behavior
Run the application locally and exercise the primary workflows to confirm behavior matches the legacy version. Pay particular attention to:

- File path handling (directory separators differ between Windows and Linux/macOS)
- Culture and encoding defaults, which may differ from .NET Framework
- Reflection-based code, which may behave differently under the new runtime

### 8. Publish a Test Build
Produce a self-contained or framework-dependent publish output and verify it runs on the intended target platform:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Adjust the `--runtime` identifier to match your deployment target (e.g., `win-x64`, `osx-x64`).