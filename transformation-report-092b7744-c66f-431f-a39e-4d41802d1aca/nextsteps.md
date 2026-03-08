# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `net472`, or any other .NET Framework moniker unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm the clean state holds outside of the transformation environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly `NU1701` (package targeting warnings) or platform-compatibility warnings, as these can indicate runtime issues even when the build succeeds.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify behavioral correctness after the migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee that runtime behavior is unchanged, especially if the project previously relied on .NET Framework-specific APIs.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any APIs that exist in the build but are not supported on all target platforms at runtime:

```bash
dotnet add package Microsoft.Windows.Compatibility
```

This package can be added temporarily to restore Windows-specific APIs if any runtime errors surface during testing on non-Windows environments.

### 6. Review `App.config` / `Web.config` Migrations
If the original project used `App.config` or `Web.config`, confirm that settings have been moved to `appsettings.json` or equivalent .NET configuration sources, as the old XML configuration system has limited support in cross-platform .NET.

### 7. Validate Output Artifacts
After a successful Release build, inspect the output directory (`bin/Release/net8.0/`) and confirm:

- The expected assemblies are present.
- No unintended `.dll` files from the old .NET Framework runtime are included.
- Any publish profiles produce the correct self-contained or framework-dependent output.

### 8. Publish the Application
Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the published output before deploying to a target environment.