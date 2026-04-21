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

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility analyzers, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests that previously passed may indicate a behavioral difference between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Verify Platform-Specific API Usage

Use the .NET Upgrade Assistant compatibility analyzer or the built-in platform compatibility warnings to identify any APIs that may behave differently across operating systems. Pay particular attention to:

- File path handling (`System.IO.Path`)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific UI frameworks
- `System.Drawing` usage (requires the `System.Drawing.Common` package and may have limitations on non-Windows platforms)

## 5. Review Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If the application is Windows-only, ensure the target includes the Windows platform identifier where necessary:

```xml
<TargetFramework>net8.0-windows</TargetFramework>
```

## 6. Check Configuration and App Settings

If the project previously used `App.config` or `Web.config`, verify that settings have been migrated to `appsettings.json` or the appropriate .NET configuration model. Confirm that connection strings, environment-specific settings, and logging configuration are functioning as expected at runtime.

## 7. Perform Runtime Validation

Run the application in a development environment and exercise the primary workflows. Compare the runtime behavior against the legacy application to confirm functional equivalence. Pay attention to:

- Exception handling behavior
- Serialization and deserialization output
- Third-party library behavior under the new runtime

## 8. Publish the Application

Once runtime validation is complete, publish the application using the appropriate profile:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Review the contents of the output directory to confirm all required assets and dependencies are present before deploying to the target environment.