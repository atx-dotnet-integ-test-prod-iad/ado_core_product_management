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

Address any warnings that surface during this step, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated to determine whether they reflect a regression introduced by the migration or a pre-existing issue.

## 4. Verify Target Framework

Open each `.csproj` file and confirm that the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0`). Ensure no projects are still referencing `net48` or other Windows-only frameworks unless intentional.

## 5. Check for Windows-Specific API Usage

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any remaining Windows-specific API calls that may not surface as build errors but will fail at runtime on non-Windows platforms:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to areas such as:
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions
- COM interop
- `System.Drawing` (requires additional packages on Linux/macOS)

## 6. Run the Application

Execute the application directly to validate runtime behavior:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Test all major functional areas of the application, comparing output and behavior against the legacy version where possible.

## 7. Review Configuration Files

Confirm that any configuration files (e.g., `appsettings.json`, connection strings, environment variables) have been correctly migrated from the legacy `App.config` or `Web.config` format to the .NET configuration system. The `Microsoft.Extensions.Configuration` package is the standard approach for this.

## 8. Validate Output Artifacts

Check that the build output in the `bin/Release` folder contains the expected assemblies and that the application runs correctly from the published output:

```bash
dotnet publish --configuration Release --output ./publish
```

Then run the published output directly to confirm it behaves as expected outside of the development environment.