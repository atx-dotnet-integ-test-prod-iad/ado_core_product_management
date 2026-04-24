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

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated to determine whether they reflect a regression introduced by the migration or a pre-existing issue.

## 4. Verify Target Framework

Open each `.csproj` file and confirm that the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other Windows-only framework monikers unless that is intentional.

## 5. Check for Windows-Specific APIs

Run the .NET Upgrade Assistant compatibility analyzer or use the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any remaining calls to Windows-specific APIs such as the registry, `System.Windows.Forms`, or `System.Drawing` (GDI+). These will not function correctly on Linux or macOS without substitution.

```bash
dotnet tool install -g dotnet-compatibility
```

## 6. Review Configuration Files

Confirm that any `App.config` or `Web.config` files have been replaced or supplemented with `appsettings.json` and the `Microsoft.Extensions.Configuration` pattern, which is the standard approach in cross-platform .NET.

## 7. Validate Runtime Behavior

Run the application manually on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement. Pay attention to:

- File path separators (`/` vs `\`)
- Case sensitivity in file system operations
- Environment variable differences across operating systems

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier such as `win-x64` or `osx-x64` as needed. Review the contents of the `publish` output folder before deploying to confirm all required assets are present.