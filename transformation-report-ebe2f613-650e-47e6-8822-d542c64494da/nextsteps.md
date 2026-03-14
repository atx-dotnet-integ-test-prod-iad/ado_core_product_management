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

Resolve any warnings about deprecated or unlisted packages by updating them to their current equivalents.

### 3. Build the Solution
Perform a full build to confirm there are no warnings that could indicate hidden compatibility issues:

```bash
dotnet build --configuration Release
```

Review any remaining warnings, particularly those related to nullable reference types, obsolete APIs, or platform compatibility analyzers (e.g., `CA1416`).

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 5. Check for Windows-Specific API Usage
Run the .NET Compatibility Analyzer to surface any calls to Windows-only APIs that may compile successfully but fail at runtime on non-Windows platforms:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to diagnostics prefixed with `CA1416`.

### 6. Verify Runtime Behavior
Run the application on each target platform (Windows, Linux, macOS) if cross-platform execution is a requirement. Confirm that file paths, line endings, culture-sensitive operations, and environment variable access behave as expected on each platform.

### 7. Review `app.config` / `web.config` Migration
If the original project used `app.config` or `web.config`, confirm that configuration has been migrated to `appsettings.json` or another supported mechanism, as `System.Configuration` has limited support in cross-platform .NET.

### 8. Publish the Application
Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --runtime <target-rid> --self-contained false
```

Replace `<target-rid>` with the appropriate Runtime Identifier, for example `win-x64`, `linux-x64`, or `osx-x64`. Review the output in the `publish` folder before deploying to the target environment.