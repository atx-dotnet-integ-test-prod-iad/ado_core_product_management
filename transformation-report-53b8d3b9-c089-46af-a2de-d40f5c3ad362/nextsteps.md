# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy the migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework. Replace any packages that only support `.NETFramework` with their cross-platform equivalents if warnings are present.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review the build output for any warnings that may indicate compatibility concerns, even if they do not cause outright failures.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review test results carefully. Any failing tests should be investigated to determine whether they indicate a regression introduced during migration or a pre-existing issue.

## 5. Validate Platform-Specific Code

Search the codebase for any APIs that were available in .NET Framework but have changed or been removed in cross-platform .NET. Common areas to check include:

- `System.Web` usage — this namespace is not available in cross-platform .NET.
- Windows Registry access (`Microsoft.Win32.Registry`) — only functional on Windows.
- `AppDomain` members that are no longer supported.
- `BinaryFormatter` — deprecated and disabled by default in .NET 5+.

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any remaining compatibility issues.

## 6. Test on Target Platforms

Since the goal is cross-platform support, run and validate the application on each intended operating system:

```bash
# On Linux or macOS
dotnet run --configuration Release
```

Pay attention to file path separators, line endings, and any OS-specific behavior in the code.

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
# Framework-dependent publish
dotnet publish --configuration Release --output ./publish

# Self-contained publish for a specific runtime
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish-linux
```

Verify the contents of the output directory and confirm the application runs correctly from the published output:

```bash
cd ./publish
dotnet AdoCore.dll
```

## 8. Review Configuration Files

Confirm that any configuration previously held in `App.config` or `Web.config` has been migrated to `appsettings.json` or environment variables, as these are the standard configuration mechanisms in cross-platform .NET.