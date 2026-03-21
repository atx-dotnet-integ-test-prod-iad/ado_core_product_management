# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless intentionally targeting multiple frameworks.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Run a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Review any warnings that surface during the build, as some warnings may indicate compatibility concerns that do not block compilation but could cause runtime issues.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify functional correctness after the migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in globalization, file path handling, or reflection behavior).

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to scan for any APIs that are present but throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Run the following if the analyzer is available:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

Pay particular attention to:
- `System.Windows.Forms` or `System.Drawing` references
- Registry access (`Microsoft.Win32.Registry`)
- COM interop usage
- Windows-specific file path assumptions (e.g., backslash separators)

### 6. Validate Runtime Behavior
Run the application manually and exercise its primary code paths. Confirm that:
- Configuration files (e.g., `appsettings.json`, formerly `app.config`) are loaded correctly
- Connection strings and external service integrations function as expected
- Logging output is consistent with expectations

### 7. Review Nullable Reference Type Warnings
Cross-platform .NET projects often enable nullable reference types by default. If the project was not previously using them, review and address any nullable warnings to improve code correctness:

```xml
<Nullable>enable</Nullable>
```

These can be addressed incrementally by annotating types or suppressing warnings where appropriate.

### 8. Publish and Smoke Test
Publish the application targeting the desired runtime and verify the output runs correctly:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` identifier to match your deployment target (e.g., `win-x64`, `osx-x64`). Run the published output and confirm the application starts and behaves as expected.