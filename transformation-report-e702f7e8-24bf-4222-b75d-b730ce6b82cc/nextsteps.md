# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build context:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility, as these can indicate subtle issues that may surface at runtime.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated before proceeding further.

## 4. Verify Target Framework

Open each `.csproj` file and confirm that the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional.

## 5. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any APIs that are Windows-specific and may not behave correctly on Linux or macOS. Pay particular attention to:

- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions
- COM interop usage
- `System.Drawing` (GDI+)

## 6. Review NuGet Package Versions

Check that all referenced NuGet packages have versions compatible with your target framework. You can use the following command to list outdated packages:

```bash
dotnet list package --outdated
```

Update packages where appropriate, and verify that no packages are being resolved through compatibility shims that could mask runtime issues.

## 7. Perform Runtime Smoke Testing

Run the application manually and exercise the primary workflows to confirm runtime behavior matches expectations from the legacy version. Pay attention to:

- File I/O operations
- Configuration file loading (e.g., `app.config` vs `appsettings.json`)
- Logging output
- Any external service or database connections

## 8. Review Configuration Migration

If the legacy project used `app.config` or `web.config`, verify that configuration values have been correctly migrated to the appropriate .NET configuration system, such as `appsettings.json` combined with `Microsoft.Extensions.Configuration`.

## 9. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required files and dependencies are present. If targeting a specific runtime, include the runtime identifier:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```