# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other .NET Framework moniker unless a multi-targeting scenario is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm there are no errors or warnings that were not caught previously:

```bash
dotnet build --configuration Release
```

Address any warnings that may indicate compatibility issues, such as platform-specific API usage warnings (CA1416).

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger trx
```

Review the test results output and investigate any failing tests, as they may indicate behavioral differences between .NET Framework and cross-platform .NET.

### 5. Check for Platform-Specific API Usage
Run the .NET Compatibility Analyzer to surface any APIs that are not supported on all platforms:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to diagnostics prefixed with `CA1416`, which indicate platform-specific API calls that may not function correctly on Linux or macOS.

### 6. Review Configuration and File Paths
Inspect any file path handling in the codebase and ensure `Path.Combine` or `Path.DirectorySeparatorChar` is used rather than hardcoded backslashes (`\`), which will not work correctly on non-Windows systems.

### 7. Review `app.config` / `web.config` Usage
Cross-platform .NET does not use `app.config` or `web.config` in the same way as .NET Framework. Confirm that any configuration has been migrated to `appsettings.json` and that `Microsoft.Extensions.Configuration` is being used where applicable.

### 8. Validate Runtime Behavior Manually
Run the application directly and exercise its primary workflows to confirm the output and behavior match expectations from the original .NET Framework version:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

### 9. Review Removed or Changed APIs
Cross-reference any use of APIs that were removed or had behavioral changes in cross-platform .NET. The official Microsoft migration guide and the [.NET Upgrade Assistant documentation](https://learn.microsoft.com/en-us/dotnet/core/porting/) provide a detailed list of known breaking changes.

### 10. Publish the Application
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (`linux-x64`, `osx-x64`, etc.) based on your deployment target. Review the publish output directory to confirm all required assets are present.