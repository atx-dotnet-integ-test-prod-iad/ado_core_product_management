# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command to ensure all NuGet packages are properly restored:

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

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review the test results carefully. Any failing tests should be investigated before proceeding further.

## 4. Audit Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0`). Ensure no projects are still referencing `net48` or other Windows-only frameworks unless that is intentional.

## 5. Check for Windows-Specific APIs

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any remaining calls to Windows-only APIs (e.g., registry access, `System.Windows.Forms`, COM interop). These will not cause build errors but will cause runtime failures on non-Windows platforms.

```bash
dotnet tool install -g dotnet-compatibility
```

## 6. Review NuGet Package Versions

Check that all NuGet dependencies have versions compatible with your target framework. Pay particular attention to any packages that were previously targeting `.NET Framework` and may have been auto-upgraded during transformation. Use the following to list outdated packages:

```bash
dotnet list package --outdated
```

## 7. Run the Application

Execute the application manually and exercise its primary workflows to verify runtime behavior:

```bash
dotnet run --project <YourStartupProject> --configuration Release
```

Compare the output and behavior against the original legacy application to identify any functional discrepancies.

## 8. Validate Configuration Files

If the project previously relied on `App.config` or `Web.config`, confirm that settings have been properly migrated to `appsettings.json` or environment variables, as `App.config` has limited support in cross-platform .NET.

## 9. Review Logging and Exception Handling

Confirm that any logging frameworks (e.g., log4net, NLog) have been updated to versions compatible with cross-platform .NET, and that exception handling behavior is consistent with the original application.