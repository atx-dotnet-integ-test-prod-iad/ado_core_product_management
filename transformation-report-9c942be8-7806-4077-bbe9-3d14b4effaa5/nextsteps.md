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

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated before proceeding further.

## 4. Verify Target Framework

Open each `.csproj` file and confirm that the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0`). Ensure no projects are still referencing `net48` or other Windows-only frameworks unless that is intentional.

## 5. Check for Windows-Specific APIs

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any remaining Windows-specific API calls that may not have been flagged during transformation:

```bash
dotnet tool install -g dotnet-platform-compat
```

Pay particular attention to areas such as:
- Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) client/server usage
- `System.Drawing` (GDI+) usage outside of Windows

## 6. Run on a Non-Windows Platform (If Applicable)

If cross-platform support is a requirement, test the application on Linux or macOS:

```bash
dotnet run --configuration Release
```

This will surface any runtime issues that are not caught at compile time.

## 7. Review Output Artifacts

Check the output directory after a Release build to confirm that the correct assemblies and dependencies are present:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` folder to ensure all expected files are included and no unintended legacy binaries are present.

## 8. Update Documentation

Update any internal documentation or README files to reflect the new target framework, build commands, and any changed project structure resulting from the migration.