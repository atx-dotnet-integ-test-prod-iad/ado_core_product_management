# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other outdated monikers unless intentionally retained.

### 2. Restore NuGet Packages
Run the following command from the solution root to confirm all dependencies resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved dependencies.

### 3. Build the Solution
Perform a full build to confirm there are no warnings that could indicate latent issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review test output for any failures or skipped tests that may indicate platform-specific behavior that was previously masked.

### 5. Check for Platform-Specific API Usage
Use the .NET Compatibility Analyzer or review the code manually for any APIs that may compile successfully but fail at runtime on non-Windows platforms. Common areas to check include:

- `System.Drawing` (requires additional packages on Linux/macOS)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific interop or P/Invoke calls
- `System.Windows.Forms` or `System.Web` references

### 6. Review `App.config` / `Web.config` Migration
If the original project used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or the appropriate .NET configuration model. Verify that the `ConfigurationManager` usage, if any, has been replaced or is backed by the `Microsoft.Extensions.Configuration.ConfigurationManager` NuGet package.

### 7. Validate Output Artifacts
After a successful Release build, inspect the output directory (`bin/Release/net8.0/` or equivalent) to confirm:

- The expected assemblies and dependencies are present.
- No legacy `.dll` files from the old framework are being copied unnecessarily.
- The executable or library behaves as expected when invoked directly:

```bash
dotnet AdoCore.dll
```

### 8. Smoke Test Core Functionality
Manually exercise the primary entry points or APIs of the application to confirm end-to-end behavior is intact, particularly any functionality that interacts with external systems such as databases, file systems, or network services.