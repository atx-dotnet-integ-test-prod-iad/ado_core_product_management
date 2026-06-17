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

Address any warnings that surface during this step, particularly those related to nullable reference types or obsolete APIs, as these can indicate subtle compatibility issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior has not changed during the migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee correct runtime behavior, so test coverage is critical at this stage.

## 4. Verify Target Framework

Open each `.csproj` file and confirm that the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0`). Ensure consistency across all projects in the solution.

```xml
<TargetFramework>net8.0</TargetFramework>
```

## 5. Check for Removed or Changed APIs

Cross-platform .NET does not include certain APIs that were available in .NET Framework. Run the .NET Upgrade Assistant compatibility analyzer or the Platform Compatibility Analyzer to identify any calls to APIs that may fail at runtime on non-Windows platforms:

```bash
dotnet add package Microsoft.DotNet.PlatformAbstractions
```

Alternatively, review the [.NET API compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) for APIs relevant to your project.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to catch platform-specific runtime issues that would not appear during a Windows-only build.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) as needed. Review the publish output directory to confirm all required files are present.

## 8. Review Configuration Files

Ensure that any `app.config` or `web.config` files have been properly migrated to `appsettings.json` or the appropriate .NET configuration model. Validate that connection strings, environment-specific settings, and logging configuration are functioning as expected at runtime.