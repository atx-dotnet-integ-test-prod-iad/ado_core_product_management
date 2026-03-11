# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless a multi-targeting scenario is intentional.

### 2. Restore NuGet Packages
Run the following command from the solution root to confirm all dependencies resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved dependencies.

### 3. Build the Solution
Perform a full build to confirm there are no warnings that may indicate runtime issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility analyzers.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify behavioral correctness after the transformation:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee that runtime behavior is unchanged from the original .NET Framework version.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the built-in platform compatibility warnings to identify any APIs that may behave differently or are unavailable on non-Windows platforms:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

Pay particular attention to areas such as:
- `System.Windows.Forms` or `System.Web` references (these do not exist in cross-platform .NET)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific interop or P/Invoke calls

### 6. Review `AdoCore.csproj` Specifically
Since `AdoCore.csproj` is listed as the most independent project in the solution, validate it first in isolation:

```bash
dotnet build src/AdoCore/AdoCore.csproj --configuration Release
```

Confirm its dependencies are all compatible with the target framework and that no transitive package references pull in .NET Framework-only assemblies.

### 7. Smoke Test Core Functionality
Manually exercise or write targeted integration tests for the core functionality provided by `AdoCore` and any projects that depend on it. Verify that data access behavior, connection handling, and any ADO.NET-specific logic produces the same results as the original implementation.

### 8. Review Configuration and Connection Strings
Cross-platform .NET does not use `app.config` or `web.config` in the same way as .NET Framework. Confirm that:
- Configuration is being read via `Microsoft.Extensions.Configuration` or an equivalent mechanism
- Connection strings and other environment-specific settings are correctly sourced at runtime

### 9. Publish and Verify Output
Produce a release publish to confirm the output is self-consistent:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to ensure all required assemblies and configuration files are present.