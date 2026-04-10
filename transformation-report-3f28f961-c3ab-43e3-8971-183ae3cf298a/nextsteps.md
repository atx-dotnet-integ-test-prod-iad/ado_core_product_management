# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

### 2. Restore NuGet Packages
Run the following command from the solution root to ensure all dependencies resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages and consider updating them.

### 3. Build the Solution
Perform a full solution build to confirm there are no errors:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during the build, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 5. Audit Removed or Changed APIs
Check for usage of APIs that behave differently on cross-platform .NET compared to .NET Framework. Common areas to review include:

- **`System.Configuration`** — `ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package.
- **`System.Drawing`** — Requires the `System.Drawing.Common` NuGet package and has platform restrictions on non-Windows systems.
- **WCF / Remoting** — These are not fully supported; verify any communication layers still function as expected.
- **Registry access** — `Microsoft.Win32.Registry` is Windows-only on cross-platform .NET.
- **`AppDomain`** — Some members are no longer supported or throw `PlatformNotSupportedException`.

### 6. Run the Application and Perform Smoke Testing
Start the application and exercise its primary workflows manually to confirm runtime behavior matches the original:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Pay particular attention to database connectivity, file I/O paths, and any platform-specific behavior that may differ on Linux or macOS if cross-platform execution is a goal.

### 7. Review Output Artifacts
Confirm that the published output is complete and correctly structured:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to ensure all required assemblies, configuration files, and assets are present.

### 8. Check for .NET Compatibility Analyzer Feedback
If not already enabled, add the .NET compatibility analyzer to surface any remaining platform-compatibility concerns:

```xml
<PackageReference Include="Microsoft.DotNet.Analyzers.Compatibility" Version="0.2.12-alpha" />
```

Alternatively, the built-in platform compatibility analysis in .NET 5+ can be enabled via:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

Review and resolve any diagnostics produced.