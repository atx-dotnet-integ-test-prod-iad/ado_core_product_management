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

Compare test results against any recorded baseline from the legacy project. Pay close attention to any tests that were previously passing and are now failing.

## 4. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended .NET version (for example, `net8.0`). Ensure no projects are still referencing `net48` or other legacy monikers unintentionally.

## 5. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any remaining Windows-specific API calls that may compile successfully but fail at runtime on non-Windows platforms:

```bash
dotnet tool install -g dotnet-compatibility
```

Review any reported diagnostics and replace platform-specific APIs with cross-platform alternatives where applicable.

## 6. Review Runtime Behavior

Run the application in its target environment and exercise the primary workflows. Areas that commonly exhibit differences after migration include:

- File path handling (`Path.Combine` vs hardcoded separators)
- Registry access (not available on Linux/macOS)
- `System.Drawing` usage (requires additional packages on non-Windows)
- COM interop or P/Invoke calls

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target platform:

```bash
# Framework-dependent deployment
dotnet publish --configuration Release --output ./publish

# Self-contained deployment for a specific platform
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the output directory to confirm all required assets and dependencies are present before deploying to the target environment.