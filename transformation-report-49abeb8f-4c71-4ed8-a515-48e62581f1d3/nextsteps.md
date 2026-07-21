# Next Steps

## Summary

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution, including `AdoCore.csproj`.

## Validation Steps

### 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Verify that no warnings or errors appear during the restore process. If any packages are flagged as incompatible with the new target framework, review the package versions and update them to versions that support the target framework.

### 2. Build the Solution

Perform a full build to confirm the absence of errors in a clean build context:

```bash
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs, missing references, or compatibility concerns that were not caught during the initial transformation.

### 3. Run Existing Tests

If the solution contains test projects, execute the test suite to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests should be investigated to determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

### 4. Review Target Framework

Open `AdoCore.csproj` and confirm that the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the runtime version available in your target deployment environment.

### 5. Check for Runtime-Specific API Usage

Even without build errors, some APIs behave differently or are unsupported at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer or review the code manually for usage of:

- `System.Windows.Forms` or `System.Drawing` (Windows-only unless using compatibility packages)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific P/Invoke calls
- `AppDomain` features that are no longer supported

Run the following to surface platform compatibility warnings during build:

```xml
<PropertyGroup>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <AnalysisMode>All</AnalysisMode>
</PropertyGroup>
```

Add this to the `.csproj` file and rebuild to review any flagged issues.

### 6. Smoke Test Core Functionality

Manually exercise the primary entry points of `AdoCore` to confirm that the application behaves as expected under the new runtime. Focus on:

- Data access operations if ADO.NET is in use
- Connection string handling, which may differ between .NET Framework and .NET
- Any configuration loading (e.g., `app.config` vs `appsettings.json`)

### 7. Review Configuration Files

.NET no longer uses `app.config` in the same way as .NET Framework. If the project previously relied on `app.config` for connection strings or application settings, verify that these have been migrated to `appsettings.json` or equivalent, and that the appropriate `Microsoft.Extensions.Configuration` packages are referenced.

### 8. Deployment

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the output directory contains all required files and that the application runs correctly from the published output on the target platform.