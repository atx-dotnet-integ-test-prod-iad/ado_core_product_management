# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and test the migrated project before deploying it.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no legacy `<TargetFrameworkVersion>` elements referencing the .NET Framework (e.g., `v4.8`) remain.

## 2. Restore Dependencies

Run the following command from the solution root to restore all NuGet packages:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not support the target framework or that have been deprecated.

## 3. Build the Solution

Perform a full build to confirm there are no compilation errors:

```bash
dotnet build --configuration Release
```

Address any warnings that surface at this stage, particularly those related to nullable reference types or obsolete APIs, as these can indicate compatibility concerns.

## 4. Run Existing Tests

If the solution contains test projects, execute the full test suite:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` results files for any failing or skipped tests. Failing tests that previously passed on .NET Framework may indicate behavioral differences in the runtime or missing platform-specific APIs.

## 5. Check for Platform-Specific API Usage

Search the codebase for APIs that are known to be unavailable or behave differently on non-Windows platforms, including but not limited to:

- `System.Windows.Forms` or `System.Web` references
- `Registry` access via `Microsoft.Win32`
- `AppDomain.GetCurrentThreadId()`
- COM interop or P/Invoke calls targeting Windows-only libraries

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package to surface these automatically.

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS as applicable) and verify that core functionality behaves as expected. Pay particular attention to:

- File path handling (`Path.Combine` vs. hardcoded separators)
- Configuration file loading (e.g., migration from `app.config` to `appsettings.json`)
- Encoding and culture-sensitive operations

## 7. Review NuGet Package Compatibility

Check that all referenced NuGet packages have versions that support your target framework. Packages that target only `net45` or similar legacy monikers may function via compatibility shims but should be replaced with actively maintained equivalents where possible.

```bash
dotnet list package --outdated
dotnet list package --deprecated
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Or for a self-contained deployment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate RID (e.g., `win-x64`, `osx-x64`) based on your target environment. Review the output directory to confirm all required assets are present before deploying.