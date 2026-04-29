# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Run a full solution build to confirm the error-free state holds outside of any IDE caching:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly `NU1701` (package targeting warnings) or `CS0618` (obsolete API usage), as these can indicate compatibility issues that may surface at runtime.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures after a framework migration often point to behavioral differences in APIs between .NET Framework and modern .NET (e.g., changes in `HttpClient`, `Thread.Abort`, reflection behavior, or serialization).

### 5. Audit Platform-Specific APIs
Use the .NET Compatibility Analyzer to identify any APIs that are Windows-only or otherwise platform-restricted. Run a build with the analyzer active by ensuring the project has:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

Pay attention to `CA1416` warnings, which flag platform-specific API calls that will not work on Linux or macOS.

### 6. Review Configuration and App Settings
If the project previously used `System.Configuration.ConfigurationManager` (i.e., `app.config` or `web.config`), verify that configuration has been migrated to `appsettings.json` and `Microsoft.Extensions.Configuration`, or that the `System.Configuration.ConfigurationManager` NuGet package has been explicitly added if the legacy approach is being retained temporarily.

### 7. Verify Output and Entry Points
Run the compiled output directly to confirm the application starts and behaves as expected:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Check that database connections, file paths, and any environment-specific settings function correctly on the target platform.

### 8. Check for Removed or Changed APIs
Review the [.NET Upgrade Assistant compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/breaking-changes) for breaking changes relevant to the .NET version you have targeted. Pay particular attention to areas such as:

- `System.Data` and ADO.NET behavior (relevant given the `AdoCore` project name)
- Reflection and dynamic code
- Threading APIs
- Encoding defaults