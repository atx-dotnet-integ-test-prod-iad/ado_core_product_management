# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless a multi-targeting scenario is intentional.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding further.

### 4. Check for Removed or Changed APIs
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.ApiCompat` tooling to identify any APIs used in the code that have been removed or changed in the target .NET version:

```bash
dotnet tool install -g dotnet-apicompat
```

Pay particular attention to areas such as:
- `System.Web` usage (not available on cross-platform .NET)
- Windows-specific APIs (e.g., registry access, WCF server-side, Windows Forms if targeting non-Windows)
- Reflection APIs that changed behavior between .NET Framework and .NET

### 5. Review NuGet Package Compatibility
Open the `.csproj` files and review each `<PackageReference>`. For any package that does not have a `net6.0`, `net7.0`, or `net8.0` compatible target framework, check NuGet.org for an updated version or an alternative package.

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

Replace or update any incompatible or vulnerable packages.

### 6. Validate Configuration Files
If the project previously used `app.config` or `web.config`, confirm that configuration has been migrated to `appsettings.json` or environment-based configuration where appropriate. The `System.Configuration.ConfigurationManager` NuGet package can bridge some gaps, but a full migration to `Microsoft.Extensions.Configuration` is preferred.

### 7. Smoke Test on Target Platforms
Run the application on each platform you intend to support (Windows, Linux, macOS) to catch any platform-specific runtime issues that would not surface at build time:

```bash
dotnet run --configuration Release
```

### 8. Publish a Self-Contained or Framework-Dependent Build
Once the above steps pass, produce a release build artifact to confirm the publish process works correctly:

```bash
# Framework-dependent
dotnet publish -c Release -o ./publish

# Self-contained (example for Linux x64)
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish-linux
```

Verify the output directory contains all expected files and that the application starts correctly from the published output.