# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional for multi-targeting.

### 2. Restore and Build Locally
Run the following commands from the root of the solution to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

### 4. Check for Removed or Changed APIs
Use the [.NET Upgrade Assistant](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any APIs that were available in .NET Framework but have changed behavior or been removed in modern .NET. Pay particular attention to:

- `System.Web` usages (not available in .NET Core/.NET 5+)
- `AppDomain` APIs with limited support
- Reflection APIs with behavioral differences
- Windows-only APIs if cross-platform support is required

### 5. Review NuGet Package Compatibility
Open the `.csproj` files and verify that all referenced NuGet packages have versions compatible with the target framework. You can check compatibility on [nuget.org](https://nuget.org) or by running:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with cross-platform support.

### 6. Validate Runtime Behavior
Run the application locally and exercise the primary workflows to confirm runtime behavior matches the legacy application. Pay attention to:

- File path handling (use `Path.Combine` rather than hardcoded separators)
- Configuration loading (e.g., `appsettings.json` vs. `app.config`/`web.config`)
- Any platform-specific code paths that may behave differently on Linux or macOS

### 7. Review `app.config` / `web.config` Migrations
If the original project used `app.config` or `web.config`, confirm that settings have been migrated to the appropriate modern configuration system, such as `appsettings.json` with `Microsoft.Extensions.Configuration`.

### 8. Publish a Release Build
Once validation is complete, produce a release publish to confirm the output is as expected:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to ensure all required assets, dependencies, and configuration files are present.