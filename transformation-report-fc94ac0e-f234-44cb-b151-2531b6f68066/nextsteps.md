# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `net472`, or any other legacy .NET Framework moniker unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm the clean state holds outside of the transformation environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly `NU1701` warnings, which indicate a package was restored for a different framework and may not be fully compatible.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review test output carefully. A successful build does not guarantee correct runtime behavior, especially after a framework migration.

### 5. Check for Windows-Specific APIs
Even without build errors, the code may use APIs that only function correctly on Windows. Use the .NET Compatibility Analyzer to surface these at build time by adding the following to any project that should be fully cross-platform:

```xml
<PropertyGroup>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <AnalysisMode>All</AnalysisMode>
</PropertyGroup>
```

Rebuild and review any `CA1416` platform compatibility warnings.

### 6. Review `app.config` / `web.config` Usage
.NET does not use `app.config` or `web.config` in the same way as .NET Framework. If the project relied on these files for configuration, verify that configuration has been migrated to `appsettings.json` or another supported mechanism and that it is being read correctly at runtime.

### 7. Validate Output Artifacts
After a Release build, inspect the output directory (`bin/Release/net8.0/` or equivalent) and confirm:
- The expected assemblies are present.
- No unintended `.dll` files from legacy references are included.
- Any required runtime assets (content files, native binaries, etc.) are present.

### 8. Smoke Test Core Functionality
Run the application manually and exercise its primary code paths. Pay particular attention to:
- File I/O paths, which may behave differently across operating systems.
- Registry access, which is Windows-only.
- COM interop or P/Invoke calls, which require platform-specific native libraries.

### 9. Publish the Application
Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --runtime <target-rid> --self-contained false
```

Replace `<target-rid>` with the appropriate Runtime Identifier, for example `win-x64`, `linux-x64`, or `osx-x64`. Review the published output before deploying to the target environment.