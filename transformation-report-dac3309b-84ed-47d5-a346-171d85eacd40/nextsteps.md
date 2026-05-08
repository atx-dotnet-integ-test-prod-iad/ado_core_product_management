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
Perform a full build to confirm there are no warnings that could indicate runtime issues:

```bash
dotnet build --configuration Release
```

Review any remaining warnings, particularly those related to nullable reference types, obsolete APIs, or platform compatibility analyzers (CA1416).

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify functional correctness:

```bash
dotnet test --configuration Release --logger trx
```

Review the output for any failing tests that may indicate behavioral differences introduced by the migration.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer or the following command to identify any platform-specific API calls that may fail on non-Windows operating systems:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to diagnostics prefixed with `CA1416` (platform compatibility).

### 6. Validate Runtime Behavior
Run the application on each target platform (Windows, Linux, macOS) to confirm consistent behavior:

```bash
dotnet run --configuration Release
```

If cross-platform execution is not feasible in your local environment, at minimum test on Linux using Windows Subsystem for Linux (WSL).

### 7. Review NuGet Package Compatibility
Confirm that all third-party NuGet packages support the target framework. Visit [nuget.org](https://www.nuget.org) and check the frameworks listed under each package version. Replace any packages that do not support your target framework with maintained alternatives.

### 8. Publish the Application
Once validation is complete, publish the application for the desired runtime:

**Framework-dependent (requires .NET runtime on target machine):**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (bundles the runtime):**
```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate Runtime Identifier (RID) for your target environment, such as `win-x64` or `osx-x64`.

### 9. Verify Published Output
Navigate to the publish output directory and confirm all expected files are present, then perform a final smoke test by executing the published binary directly.