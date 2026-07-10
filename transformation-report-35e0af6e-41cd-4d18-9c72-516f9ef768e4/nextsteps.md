# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `net472`, or any other .NET Framework moniker unless that is intentional for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Run a full solution build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that may indicate compatibility issues even if the build succeeds.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in globalization, file path handling, or reflection behavior).

### 5. Check for Platform-Specific API Usage
Use the .NET Compatibility Analyzer or the following command to scan for APIs that may not be supported on all platforms:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to warnings with codes such as `CA1416` (platform compatibility), as these indicate APIs that are Windows-only and will fail on Linux or macOS.

### 6. Verify Configuration and File Paths
Review any code that constructs file paths or reads configuration files. Replace backslash-based paths with `Path.Combine` or forward-slash equivalents to ensure cross-platform compatibility.

### 7. Test on Target Platforms
If the goal is to run on non-Windows platforms, execute the application on each intended target OS (Linux, macOS) to surface any runtime issues that static analysis may not catch:

```bash
dotnet run --configuration Release
```

### 8. Review Removed or Changed APIs
Cross-reference the project's usage of the following commonly breaking areas when migrating from .NET Framework:

- `System.Web` — not available in cross-platform .NET
- `AppDomain` — partially available
- `BinaryFormatter` — disabled by default in .NET 5+
- Windows Registry access — Windows-only
- `Thread.Abort` — throws `PlatformNotSupportedException`

Use the [.NET Upgrade Assistant compatibility report](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) if a detailed API surface report is needed.

### 9. Publish a Self-Contained Build
Once validation is complete, produce a publish output to confirm the final artifact is well-formed:

```bash
dotnet publish --configuration Release --self-contained false --output ./publish
```

Review the output directory to confirm all expected assemblies and assets are present.