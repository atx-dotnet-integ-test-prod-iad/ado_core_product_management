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

Review test output carefully. Any failing tests should be investigated to determine whether they reflect a regression introduced during the migration or a pre-existing issue.

## 4. Verify Target Framework

Open each `.csproj` file and confirm that the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0`). Ensure no projects are still referencing `net48` or other Windows-only frameworks unless that is intentional.

## 5. Check for Windows-Specific APIs

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any remaining Windows-specific API calls that may compile successfully but fail at runtime on non-Windows platforms:

```bash
dotnet add package Microsoft.Windows.Compatibility
```

If cross-platform runtime behavior is a requirement, replace or conditionally compile any Windows-specific code paths.

## 6. Review Configuration and File Paths

Inspect any file path handling, registry access, or environment variable usage in the codebase. Ensure paths use `Path.Combine` and `Path.DirectorySeparatorChar` rather than hardcoded backslashes.

## 7. Test on Target Platforms

Run and test the application on each platform you intend to support (e.g., Linux, macOS, Windows) to surface any runtime issues that are not caught at compile time:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier for your deployment target (e.g., `win-x64`, `osx-x64`). Review the publish output directory to confirm all required assets are present.

## 9. Review Output for Trimming Warnings (Optional)

If you intend to publish with trimming enabled, add `<PublishTrimmed>true</PublishTrimmed>` to your project file and re-run the publish command. Address any trimming warnings to ensure runtime stability.