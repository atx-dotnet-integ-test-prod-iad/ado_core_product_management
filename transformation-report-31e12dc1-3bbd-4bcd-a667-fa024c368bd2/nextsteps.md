# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. You can check your installed SDKs by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version mismatches. If any packages targeting the old .NET Framework are still present, locate their cross-platform equivalents on [NuGet.org](https://www.nuget.org).

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete APIs, as these can indicate areas that may cause runtime issues.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify behavioral correctness after the migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee that runtime behavior is identical to the original .NET Framework version.

## 5. Check for Platform-Specific API Usage

Audit the codebase for any APIs that were available in .NET Framework but have been removed or behave differently in cross-platform .NET. Common areas to check include:

- `System.Web` usage (not available in cross-platform .NET)
- `AppDomain` APIs with limited support
- Windows Registry access (`Microsoft.Win32.Registry`)
- `BinaryFormatter` (disabled by default in .NET 5+)
- WCF server-side components

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package to surface these issues systematically.

## 6. Test on Target Platforms

Since the goal is cross-platform support, run and validate the application on each intended operating system (Windows, Linux, macOS) to catch platform-specific runtime issues:

```bash
dotnet run --configuration Release
```

Pay particular attention to:

- File path separators (`\` vs `/`)
- Case sensitivity in file system operations
- Environment variable differences across operating systems

## 7. Publish the Application

Once validation is complete, publish the application for your target runtime. For a self-contained deployment targeting Linux x64 as an example:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

For a framework-dependent deployment:

```bash
dotnet publish --configuration Release
```

Review the contents of the `publish` output folder to confirm all required assets are present before deploying to the target environment.