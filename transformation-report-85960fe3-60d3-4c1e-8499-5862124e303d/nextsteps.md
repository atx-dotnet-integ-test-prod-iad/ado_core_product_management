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

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not regressed during the transformation:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated to determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Verify Platform-Specific API Usage

Cross-platform .NET does not support certain Windows-specific APIs. Use the .NET Compatibility Analyzer to identify any remaining platform-specific calls:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Review any analyzer warnings in your IDE or build output and replace or conditionally compile any APIs flagged as Windows-only if cross-platform support is required.

## 5. Review Configuration and App Settings

Ensure that any configuration files (e.g., `appsettings.json`, environment variables) have been migrated from the legacy `App.config` or `Web.config` format. Confirm that the `Microsoft.Extensions.Configuration` setup reads values correctly at runtime.

## 6. Test Runtime Behavior

Run the application in a local environment and exercise its primary workflows. Pay particular attention to:

- File system path handling, as path separators differ between Windows and Unix-based systems.
- Registry access, which is not available on non-Windows platforms.
- Any use of `System.Drawing` or WinForms/WPF components, which have limited or no cross-platform support.

## 7. Validate Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If the project is intended to remain Windows-only, ensure the target is set appropriately:

```xml
<TargetFramework>net8.0-windows</TargetFramework>
```

## 8. Publish the Application

Once validation is complete, publish the application using the following command:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required assemblies and configuration files are present before deploying to the target environment.