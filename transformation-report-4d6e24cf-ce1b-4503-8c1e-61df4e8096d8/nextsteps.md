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

Address any warnings that surface during this step, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during the migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated to determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Verify Platform-Specific Behavior

Cross-platform .NET differs from .NET Framework in several areas. Manually verify the following:

- **File system paths**: Ensure no hardcoded Windows-style paths (e.g., `C:\`) exist in configuration or code.
- **Registry access**: `Microsoft.Win32.Registry` is not available on Linux/macOS. If the project uses registry access, it will need to be replaced with an alternative configuration mechanism.
- **Windows-only APIs**: Check for usage of APIs such as `System.Drawing`, WCF, or `System.Web`, which may have limited or no support on non-Windows platforms.
- **Culture and encoding**: Verify that string formatting, date handling, and encoding behavior matches expectations on the target platform.

## 5. Review Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If the project needs to support multiple frameworks, consider using `<TargetFrameworks>` (plural) with a semicolon-separated list.

## 6. Check NuGet Package Compatibility

Review all referenced NuGet packages and confirm they support the target framework. Packages that have not been updated in several years may only target `net45` or similar legacy monikers. Use the following command to inspect package versions:

```bash
dotnet list package --outdated
```

Update packages where newer, compatible versions are available.

## 7. Run the Application

Execute the application directly to perform a smoke test:

```bash
dotnet run --project <YourProjectName> --configuration Release
```

Step through the primary workflows of the application to confirm runtime behavior is correct.

## 8. Publish the Application

Once validation is complete, publish the application for the target environment. For a self-contained deployment targeting a specific runtime:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained true
```

Replace `<runtime-identifier>` with the appropriate value for your target platform, such as `win-x64`, `linux-x64`, or `osx-x64`.

For a framework-dependent deployment (requires .NET runtime installed on the target machine):

```bash
dotnet publish --configuration Release
```

Review the contents of the `publish` output directory before deploying to confirm all required files are present.