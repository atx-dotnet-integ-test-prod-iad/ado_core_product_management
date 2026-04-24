# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or obsolete APIs, as these can indicate subtle compatibility issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests should be investigated to determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Verify Platform-Specific API Usage

Review the codebase for any APIs that were available in .NET Framework but may behave differently or have limited support in cross-platform .NET. Common areas to check include:

- `System.Drawing` (requires additional packages on non-Windows platforms)
- Windows Registry access (`Microsoft.Win32.Registry`)
- WCF server-side components
- `AppDomain` usage
- `BinaryFormatter` (deprecated and disabled by default)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining compatibility concerns.

## 5. Check Configuration Files

Ensure that any `app.config` or `web.config` files have been properly migrated to `appsettings.json` or the appropriate .NET configuration model. Verify that connection strings, application settings, and environment-specific values are correctly represented.

## 6. Validate Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If cross-platform support is required, confirm that no project is still targeting `net48` or another .NET Framework moniker unintentionally.

## 7. Smoke Test the Application

Run the application manually and exercise its primary workflows to confirm runtime behavior matches expectations from the legacy version. Pay particular attention to:

- File I/O paths (path separators differ on Linux/macOS)
- Culture and encoding defaults
- Thread and synchronization behavior

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required assets, dependencies, and configuration files are present before deploying to the target environment.