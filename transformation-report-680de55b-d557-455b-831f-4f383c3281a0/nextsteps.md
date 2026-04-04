# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Debug
dotnet build --configuration Release
```

Address any warnings that surface during the build, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior matches the pre-migration state:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Compare test results against any recorded baselines from the original .NET Framework version if available.

## 4. Validate Platform-Specific Behavior

Since this is a cross-platform migration, run the application on each target platform (Windows, Linux, macOS) if applicable. Pay particular attention to:

- File path handling (`Path.Combine` vs hardcoded separators)
- Registry access calls, which are Windows-only
- Any use of `System.Drawing` or other packages that may require additional native dependencies on non-Windows platforms
- P/Invoke calls or native interop that may behave differently across operating systems

## 5. Review Compatibility Analyzer Output

Install and run the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.ApiCompat` tool to surface any remaining API compatibility concerns that do not manifest as build errors:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <solution-file>.sln
```

## 6. Review Target Framework Monikers

Open each `.csproj` file and confirm the `<TargetFramework>` value is set to the intended version (e.g., `net8.0`). Ensure no projects are still referencing `net472` or similar legacy monikers unless intentional multi-targeting is in place.

## 7. Smoke Test Core Functionality

Manually exercise the primary workflows of the application to confirm end-to-end functionality. Focus on areas that historically relied on Windows-specific or COM-based APIs, as these are the most common sources of runtime failures that do not appear as build errors.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# Framework-dependent
dotnet publish --configuration Release --output ./publish

# Self-contained for a specific platform
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the contents of the output directory and confirm the application runs correctly from the published output before promoting it to any environment.