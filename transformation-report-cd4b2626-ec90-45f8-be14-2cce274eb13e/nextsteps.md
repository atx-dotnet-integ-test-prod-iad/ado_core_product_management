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

Address any warnings that surface during this step, particularly those related to nullable reference types or obsolete APIs, as these may indicate areas that need attention.

## 3. Run Existing Tests

If the solution contains test projects, execute the test suite to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests should be investigated to determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Verify Platform-Specific Code

Review the codebase for any APIs that were available in .NET Framework but have changed or been removed in cross-platform .NET. Common areas to check include:

- `System.Web` usage (not available in cross-platform .NET)
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage
- Remoting APIs
- Binary serialization (`BinaryFormatter`)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.ApiCompat` tool to identify any remaining compatibility concerns.

## 5. Test on Target Platforms

Since the project is now cross-platform, validate it on each intended operating system (Windows, Linux, macOS) if applicable:

```bash
dotnet run --configuration Release
```

Pay attention to file path separators, line endings, and any OS-specific behavior that may differ across platforms.

## 6. Review Target Framework Monikers

Open each `.csproj` file and confirm the `<TargetFramework>` or `<TargetFrameworks>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If multi-targeting is required, ensure all target frameworks are listed and tested.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier for your environment (`win-x64`, `osx-x64`, etc.). Review the publish output directory to confirm all required files are present.

## 8. Review Configuration Files

Ensure that any configuration previously stored in `App.config` or `Web.config` has been properly migrated to `appsettings.json` or environment variables, as these are the standard configuration mechanisms in cross-platform .NET.