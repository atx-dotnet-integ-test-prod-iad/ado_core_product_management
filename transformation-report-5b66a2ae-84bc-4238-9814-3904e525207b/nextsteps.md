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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if the build succeeds.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding.

### 4. Check for Removed or Changed APIs
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.ApiCompat` tooling to identify any APIs that were available in the legacy framework but have been removed or changed in the target framework:

```bash
dotnet tool install -g dotnet-apicompat
```

Pay particular attention to:
- `System.Web` usages (not available in cross-platform .NET)
- Windows-specific APIs (e.g., registry access, WCF server-side, Windows Forms if targeting non-Windows)
- Reflection APIs that changed behavior between .NET Framework and .NET

### 5. Review NuGet Package Compatibility
Open the `.csproj` files and review all `<PackageReference>` entries. For each package:
- Confirm it has a version compatible with the target framework by checking [nuget.org](https://www.nuget.org)
- Replace any packages that only supported .NET Framework with their cross-platform equivalents

### 6. Validate Configuration and App Settings
If the project uses `app.config` or `web.config`, confirm that the relevant settings have been migrated to `appsettings.json` or the appropriate .NET configuration model. The legacy XML-based configuration system has limited support in cross-platform .NET.

### 7. Test on Target Operating Systems
If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear at build time.

```bash
dotnet run --configuration Release
```

### 8. Review Output Artifacts
Publish the project and inspect the output to confirm all expected files, dependencies, and assets are present:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the published output runs correctly in an environment that mirrors production.