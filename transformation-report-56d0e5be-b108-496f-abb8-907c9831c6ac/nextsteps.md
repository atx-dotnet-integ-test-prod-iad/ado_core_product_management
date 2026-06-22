# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other legacy/end-of-life monikers unless intentionally kept for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts.

### 3. Build the Solution
Perform a clean build to confirm there are no residual issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete API usage, as these can indicate latent runtime issues.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failed or skipped tests and investigate accordingly.

### 5. Verify Platform-Specific Code
Search the codebase for any APIs that were Windows-only in .NET Framework and may behave differently or throw `PlatformNotSupportedException` on Linux or macOS. Common areas to check include:

- `System.Drawing` (GDI+)
- `Microsoft.Win32.Registry`
- Windows Communication Foundation (WCF) server-side APIs
- `System.Security.Permissions`

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package to identify remaining platform dependencies.

### 6. Run on Target Platforms
Execute the application on each platform you intend to support (Windows, Linux, macOS) and validate core functionality manually, particularly any I/O, networking, or serialization paths.

### 7. Review Configuration Files
Confirm that any `app.config` or `web.config` files have been migrated to `appsettings.json` or the appropriate .NET configuration model. Legacy XML-based configuration is not automatically carried over in all cases.

### 8. Check for Publish Readiness
Perform a test publish to confirm the output is complete:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to ensure all expected assemblies, assets, and configuration files are present before deploying to the target environment.