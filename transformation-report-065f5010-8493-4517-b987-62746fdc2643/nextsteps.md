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

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee functional correctness, so any failing tests should be investigated before proceeding.

## 4. Verify Target Framework

Open each `.csproj` file and confirm that the `<TargetFramework>` element references the intended .NET version (e.g., `net8.0`). Ensure consistency across all projects in the solution to avoid inter-project compatibility issues.

## 5. Review Removed or Changed APIs

Cross-platform .NET does not include certain Windows-specific APIs that were available in .NET Framework. Run the .NET Upgrade Assistant compatibility analyzer or the Platform Compatibility Analyzer to identify any calls that may fail at runtime on non-Windows platforms:

```bash
dotnet add package Microsoft.DotNet.PlatformAbstractions
```

Pay particular attention to areas such as:
- Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) server-side APIs
- `System.Drawing` (requires additional packages on Linux/macOS)
- `AppDomain` usage

## 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that static analysis may not catch.

## 7. Review Configuration Files

.NET Framework used `App.config` and `Web.config` files. Confirm that any configuration has been migrated to `appsettings.json` or environment-based configuration using `Microsoft.Extensions.Configuration`. Verify that connection strings, application settings, and logging configuration are functioning as expected at runtime.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment target. Review the publish output directory to confirm all required files are present.