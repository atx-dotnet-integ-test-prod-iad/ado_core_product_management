# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other outdated monikers unless intentionally targeting multiple frameworks.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if they do not produce build errors.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding further.

### 4. Check for Removed or Changed APIs
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.ApiCompat` tooling to identify any APIs that were available in the legacy framework but have been removed or altered in the target framework:

```bash
dotnet tool install -g dotnet-apicompat
```

Pay particular attention to:
- `System.Web` usages (not available in cross-platform .NET)
- Windows-only APIs (e.g., registry access, WCF server-side, Windows Forms if targeting non-Windows)
- Any `[Obsolete]` warnings surfaced during the build step above

### 5. Audit NuGet Package Versions
Open the solution in Visual Studio or run the following to check for outdated or vulnerable packages:

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

Update packages where appropriate, and verify that no packages are pulling in transitive dependencies tied to the legacy framework.

### 6. Validate Platform-Specific Behavior
If the application contains any platform-specific code paths (file system paths, process invocations, interop calls), test the application on each intended target platform (Windows, Linux, macOS) to confirm consistent behavior.

### 7. Review Configuration and App Settings
Confirm that configuration files have been migrated correctly:
- `app.config` / `web.config` entries should be moved to `appsettings.json` or environment variables where applicable.
- Connection strings and environment-specific values should be verified in the new configuration system.

### 8. Smoke Test the Application
Run the application manually and exercise its primary workflows to confirm there are no runtime exceptions that would not be caught by unit tests alone:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

### 9. Publish a Release Build
Once validation is complete, produce a published output to confirm the publish pipeline works correctly:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to ensure all required assets, dependencies, and configuration files are present.