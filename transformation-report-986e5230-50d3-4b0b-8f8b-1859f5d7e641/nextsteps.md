# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other .NET Framework monikers unless a multi-targeting scenario is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm there are no warnings that could indicate runtime issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify behavioral correctness after the transformation:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee that runtime behavior is unchanged.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any remaining Windows-specific API calls that may compile successfully but fail at runtime on non-Windows platforms. You can also enable the platform compatibility analyzer by ensuring the following is present in your `.csproj`:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

### 6. Review `app.config` / `web.config` Migrations
If the original project used `app.config` or `web.config`, confirm that configuration has been migrated to `appsettings.json` or another supported mechanism, and that `System.Configuration` references have been replaced where applicable.

### 7. Verify Output Artifacts
Publish the project and inspect the output directory to confirm all expected assemblies, assets, and configuration files are present:

```bash
dotnet publish --configuration Release --output ./publish
```

### 8. Smoke Test the Application
Run the published output directly to confirm the application starts and core functionality operates as expected:

```bash
dotnet ./publish/AdoCore.dll
```

Adjust the entry point name as appropriate for your project type.