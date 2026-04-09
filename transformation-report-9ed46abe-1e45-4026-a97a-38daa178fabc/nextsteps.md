# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command in the root of your solution to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee correct runtime behavior, so test coverage is important at this stage.

## 4. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure all projects in the solution are targeting a consistent and supported framework version.

## 5. Review Removed or Changed APIs

Cross-platform .NET does not include certain Windows-specific APIs that were available in .NET Framework. Manually review the codebase for usage of the following, which may compile but fail at runtime on non-Windows platforms:

- `System.Windows.Forms` or `System.Web` namespaces
- Registry access via `Microsoft.Win32`
- COM interop
- `AppDomain.SetupInformation`
- Platform-specific file path assumptions (e.g., backslashes)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package where applicable.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues not caught during compilation.

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier for your target environment (e.g., `linux-x64`, `osx-x64`).

## 8. Review Output Artifacts

Inspect the contents of the publish output directory to confirm all required files, configuration files, and assets are present before deploying to the target environment.