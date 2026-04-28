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
Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Review any warnings that surface, as some may indicate compatibility issues that do not block the build but could cause runtime problems.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review test output carefully, paying attention to any tests that were previously passing and are now failing or skipped.

### 5. Check for Windows-Specific API Usage
Even when a project compiles without errors, it may contain APIs that are only supported on Windows. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Look for `CA1416` warnings, which indicate platform-specific API calls that may fail on Linux or macOS at runtime.

### 6. Run on Target Platforms
If cross-platform support is a goal, execute the application on each intended operating system (Windows, Linux, macOS) and verify behavior is consistent. Pay particular attention to:

- File path separators
- Environment variable access
- Registry access (not available on non-Windows platforms)
- Windows-specific libraries such as `System.Drawing.Common`

### 7. Review `AdoCore.csproj` Specifically
Since `AdoCore` is the most independent project in the solution (listed last), confirm the following within its `.csproj`:

- No remaining references to `System.Data.OleDb` or other Windows-only ADO providers unless explicitly required
- Any database connectivity libraries (e.g., `System.Data.SqlClient`) have been replaced with their cross-platform equivalents (e.g., `Microsoft.Data.SqlClient`)
- Connection string handling does not rely on Windows-integrated security in environments where it is unavailable

### 8. Publish a Test Build
Produce a self-contained publish output to verify the final artifact is complete:

```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64
```

Adjust the `--runtime` identifier to match your deployment target. Confirm the output directory contains all required files and the application starts correctly.