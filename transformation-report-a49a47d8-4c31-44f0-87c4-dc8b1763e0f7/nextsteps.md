# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this aligns with the runtime available in your target environment.

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or compatibility issues that were not caught as errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between the legacy .NET Framework and the new .NET runtime.

## 4. Check for Runtime Compatibility Issues

Some APIs that compiled successfully may behave differently or throw exceptions at runtime on cross-platform .NET. Pay particular attention to:

- **Windows-only APIs**: Features such as the registry, WCF server-side hosting, `System.Drawing`, or COM interop may require additional NuGet packages (e.g., `Microsoft.Win32.Registry`, `System.Drawing.Common`) or platform-specific guards.
- **Configuration**: `app.config`-based configuration is not fully supported. Migrate to `appsettings.json` using `Microsoft.Extensions.Configuration` if applicable.
- **Database access**: If `AdoCore` implies ADO.NET usage, verify that the database drivers (e.g., `System.Data.SqlClient` vs `Microsoft.Data.SqlClient`) are the correct modern equivalents.

## 5. Review NuGet Package Versions

Open the `.csproj` file and inspect all `<PackageReference>` entries. Ensure no packages are pinned to versions that target only .NET Framework. Use the following command to check for outdated packages:

```bash
dotnet list package --outdated
```

Update packages where appropriate, testing after each update.

## 6. Validate Cross-Platform Behavior (If Required)

If cross-platform support is a goal, run the application on each target operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues. Use conditional compilation or runtime checks (`RuntimeInformation.IsOSPlatform`) where platform-specific code paths are necessary.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# Framework-dependent deployment
dotnet publish --configuration Release --output ./publish

# Self-contained deployment for a specific platform
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files are present before deploying to the target environment.