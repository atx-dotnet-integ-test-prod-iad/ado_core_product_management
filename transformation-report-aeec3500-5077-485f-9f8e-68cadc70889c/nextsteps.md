# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. Run the following to confirm your SDK version:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages and consider updating them to their current stable versions.

## 3. Build the Solution

Perform a full build in Release configuration to confirm there are no errors outside of Debug mode:

```bash
dotnet build --configuration Release
```

## 4. Run the Test Suite

If the solution contains test projects, execute all tests to verify that existing behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests and address them before proceeding.

## 5. Check for Platform-Specific APIs

Search the codebase for any APIs that may have been available in .NET Framework but are unavailable or behave differently in cross-platform .NET. Common areas to check include:

- `System.Windows.Forms` or `System.Web` references
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions (backslashes, drive letters)
- `AppDomain` usage that relied on full .NET Framework behavior

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to surface any remaining compatibility issues.

## 6. Review Configuration Files

If the project previously relied on `App.config` or `Web.config`, confirm that settings have been migrated to the appropriate .NET configuration system, such as `appsettings.json` with `Microsoft.Extensions.Configuration`.

## 7. Test on Target Platforms

If cross-platform support is a goal, run the built output on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime. For a self-contained deployment targeting Linux x64 as an example:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

For a framework-dependent deployment:

```bash
dotnet publish --configuration Release
```

Review the contents of the `publish` output directory to confirm all required files are present before deploying to the target environment.