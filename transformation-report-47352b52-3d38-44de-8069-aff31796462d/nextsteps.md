# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net48`, `netcoreapp`, or other legacy monikers unless intentionally targeting multiple frameworks.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved references.

### 3. Build the Solution
Perform a clean build to confirm there are no hidden warnings or errors:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings (CA1416).

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify existing behavior is preserved:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failed or skipped tests that may indicate behavioral regressions introduced during the migration.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the built-in Roslyn analyzers to identify any APIs that are Windows-only or otherwise platform-restricted. Pay particular attention to:

- `System.Windows.Forms` or `System.Drawing` references
- Registry access (`Microsoft.Win32.Registry`)
- COM interop or P/Invoke calls
- `System.Web` references (not available in cross-platform .NET)

Run the analyzer with:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

### 6. Verify Runtime Behavior
Run the application on each target platform (Windows, Linux, macOS) if cross-platform support is a goal. Confirm that file paths, line endings, environment variables, and culture-sensitive operations behave as expected on each platform.

### 7. Review Configuration Files
Check that any `app.config` or `web.config` files have been migrated to `appsettings.json` or the appropriate .NET configuration model. The legacy XML-based configuration system has limited support in modern .NET.

### 8. Publish the Application
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) as needed. Review the publish output directory to confirm all required assets are present before deployment.