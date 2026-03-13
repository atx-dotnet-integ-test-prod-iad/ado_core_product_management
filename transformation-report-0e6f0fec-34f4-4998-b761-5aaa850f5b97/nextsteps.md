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

If the solution contains test projects, execute them to verify that behavior has not changed during the migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated to determine whether they reflect a regression introduced during migration or a pre-existing issue.

## 4. Validate Platform-Specific APIs

Review the codebase for any remaining usage of Windows-specific APIs (e.g., `System.Windows.Forms`, `Microsoft.Win32`, `System.Drawing` in a non-cross-platform context). Use the .NET Compatibility Analyzer to assist with this:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Run the build again after adding the analyzer and review any reported diagnostics.

## 5. Review Target Framework Monikers

Open each `.csproj` file and confirm that the `<TargetFramework>` or `<TargetFrameworks>` element is set to the intended cross-platform target, such as `net8.0`. Example:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If multiple targets are needed, use `<TargetFrameworks>net8.0;net472</TargetFrameworks>`.

## 6. Check Runtime Behavior

Run the application manually and exercise the primary workflows. Pay attention to:

- File path handling (use `Path.Combine` and avoid hardcoded backslashes)
- Environment-specific configuration (e.g., `appsettings.json` vs. legacy `app.config`)
- Any reflection-based code that may behave differently under .NET's trimming or AOT scenarios

## 7. Review NuGet Package Versions

Confirm that all referenced NuGet packages have versions compatible with your target framework. Check for packages that may have been replaced by built-in .NET APIs:

```bash
dotnet list package --outdated
```

Update packages where appropriate using:

```bash
dotnet add package <PackageName> --version <NewVersion>
```

## 8. Publish the Application

Once validation is complete, publish the application for your target platform:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained true
```

Replace `<runtime-identifier>` with the appropriate value, such as `win-x64`, `linux-x64`, or `osx-x64`. Review the publish output directory to confirm all required assets are present before deploying.