# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. Run the following to confirm:

```bash
dotnet --version
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings related to deprecated or unlisted packages. If any packages targeting the old .NET Framework are present, check for their .NET-compatible equivalents on [NuGet.org](https://www.nuget.org).

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Review all warnings in the output, even if the build succeeds. Warnings related to nullable reference types, obsolete APIs, or platform compatibility should be addressed before deployment.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify functional correctness:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and trace them back to behavioral differences between .NET Framework and modern .NET, such as changes in globalization, threading, or HTTP handling.

## 5. Check for Platform-Specific Code

Search the codebase for APIs that may behave differently or are unsupported on non-Windows platforms, including:

- `System.Drawing` (requires `libgdiplus` on Linux/macOS or use of an alternative like `SkiaSharp`)
- `Microsoft.Win32` registry access
- Windows-specific P/Invoke calls
- `AppDomain` usage beyond what is supported in modern .NET

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package to identify these areas.

## 6. Validate Configuration and App Settings

If the project previously used `app.config` or `web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables where appropriate. Verify that `ConfigurationManager` usage has been replaced with `Microsoft.Extensions.Configuration` if applicable.

## 7. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to catch any runtime issues that do not surface during compilation:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

**Framework-dependent deployment:**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained deployment (example for Linux x64):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Review the contents of the `./publish` directory to confirm all required files are present before deploying to the target environment.