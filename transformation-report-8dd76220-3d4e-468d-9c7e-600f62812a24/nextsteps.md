# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Run a full build to confirm there are no warnings that could indicate subtle issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee correct runtime behavior.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any remaining Windows-only API calls that may compile successfully but fail at runtime on non-Windows platforms. You can also enable the platform compatibility analyzer by adding the following to your `.csproj`:

```xml
<PropertyGroup>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <AnalysisMode>All</AnalysisMode>
</PropertyGroup>
```

### 6. Review `app.config` / `web.config` Migrations
If any projects previously relied on `app.config` or `web.config`, confirm that configuration has been migrated to `appsettings.json` or the appropriate .NET configuration provider. Legacy config files are not fully supported in cross-platform .NET.

### 7. Validate Runtime Behavior
Run the application manually and exercise the primary workflows to confirm behavior matches the legacy version. Pay particular attention to:

- File I/O paths (avoid hardcoded Windows-style paths)
- Registry access (not available on non-Windows platforms)
- COM interop or P/Invoke calls
- `System.Drawing` usage (requires `libgdiplus` on Linux or migration to an alternative library)

### 8. Publish the Application
Once validation is complete, publish the application for the target platform:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with your intended runtime identifier (e.g., `win-x64`, `osx-x64`). Review the publish output directory to confirm all required assets are present.