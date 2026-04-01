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

If the solution contains test projects, execute them to verify that behavior has not changed during the migration:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests should be investigated to determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Verify Platform-Specific Behavior

Cross-platform .NET may behave differently from .NET Framework in the following areas. Manually verify these if they are relevant to your project:

- **File system paths**: Path separators differ between Windows and Unix-based systems. Ensure no hardcoded backslashes (`\`) are used in path construction.
- **Registry access**: `Microsoft.Win32.Registry` is Windows-only. If your code accesses the registry, it will not function on Linux or macOS.
- **Windows Communication Foundation (WCF)**: WCF server-side is not supported in cross-platform .NET. If your project uses WCF, consider migrating to gRPC or CoreWCF.
- **`System.Drawing`**: On non-Windows platforms, `System.Drawing.Common` requires native dependencies. Consider migrating to an alternative such as `SkiaSharp` or `ImageSharp`.
- **`AppDomain`**: Some `AppDomain` APIs are not supported and will throw `PlatformNotSupportedException`.

## 5. Review Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If you need to support multiple frameworks simultaneously, consider using `<TargetFrameworks>` (plural):

```xml
<TargetFrameworks>net8.0;net472</TargetFrameworks>
```

## 6. Check for Removed or Changed APIs

Use the [.NET Upgrade Assistant](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the [.NET Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/analyzers) to scan for any API usage that is unsupported or has changed behavior in the target framework.

```bash
dotnet add package Microsoft.DotNet.ApiCompat
```

## 7. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a Windows-only build.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) as needed. Review the output directory to confirm all required files are present before deploying.