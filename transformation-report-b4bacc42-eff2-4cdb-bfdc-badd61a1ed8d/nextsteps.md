# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

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

Address any warnings that appear, particularly those related to nullable reference types or obsolete APIs, as these may indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior matches the pre-migration state:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee correct runtime behavior, so test coverage is important at this stage.

## 4. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0`). Ensure no projects are still referencing `net48` or other Windows-only frameworks unless explicitly required.

## 5. Check for Windows-Specific API Usage

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any remaining Windows-specific API calls that may compile successfully but fail at runtime on non-Windows platforms:

```bash
dotnet add package Microsoft.Windows.Compatibility
```

Alternatively, use the platform compatibility analyzer warnings surfaced during the build step above.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each target operating system (e.g., Linux, macOS) to catch any platform-specific runtime issues that would not surface on Windows alone.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier for your deployment target (e.g., `win-x64`, `osx-x64`). Use `--self-contained true` if you require the .NET runtime to be bundled with the output.

## 8. Review Output Artifacts

Inspect the `publish` output directory to confirm all expected assemblies, configuration files, and assets are present before deploying to the target environment.