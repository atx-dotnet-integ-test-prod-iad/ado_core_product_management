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
Perform a full build to confirm there are no warnings that could indicate latent issues:

```bash
dotnet build --configuration Release
```

Review any warnings in the output, particularly those related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Investigate any failing tests to determine whether they are caused by behavioral differences between the old and new runtime.

### 5. Check for Platform-Specific API Usage
Use the .NET Compatibility Analyzer to identify any APIs that are Windows-only or otherwise platform-restricted. This can surface issues that do not produce build errors but will fail at runtime on non-Windows platforms:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to diagnostics prefixed with `CA1416` (platform compatibility).

### 6. Run the Application
Execute the application directly to confirm it starts and operates correctly:

```bash
dotnet run --project AdoCore --configuration Release
```

Test the primary workflows and verify that output and behavior match expectations from the legacy version.

### 7. Verify Configuration Files
Check that any configuration files (e.g., `appsettings.json`, connection strings, environment-specific settings) have been migrated from the legacy `App.config` or `Web.config` format and are being read correctly by the new configuration system.

### 8. Review Removed References
Confirm that any assemblies previously referenced from the Global Assembly Cache (GAC) or via legacy COM interop have been replaced with their NuGet equivalents or appropriate .NET alternatives.