# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

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

Review the output for any warnings about deprecated packages or packages that do not support the target framework. If any packages are flagged, check NuGet.org for updated versions and replace them in the `.csproj` file.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review the build output for any warnings, particularly those related to obsolete APIs or platform-specific code paths that may not behave as expected on non-Windows platforms.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify existing functionality is intact:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review test results carefully. Any failures that did not exist prior to migration should be investigated, as they may indicate behavioral differences between .NET Framework and modern .NET.

## 5. Check for Platform-Specific Code

Search the codebase for APIs that were Windows-specific in .NET Framework and may behave differently or be unavailable in cross-platform .NET. Common areas to check include:

- `System.Windows.Forms` or `System.Web` references
- Registry access (`Microsoft.Win32.Registry`)
- COM interop or P/Invoke calls
- `AppDomain` usage
- `BinaryFormatter` (deprecated and disabled by default in modern .NET)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify these issues if needed.

## 6. Validate Runtime Behavior

Run the application manually and exercise its primary workflows to confirm runtime behavior matches the legacy version. Pay particular attention to:

- File I/O paths (path separators differ between Windows and Linux/macOS)
- Configuration file loading (e.g., migration from `app.config` to `appsettings.json`)
- Database connectivity if ADO.NET is in use (given the project name `AdoCore`)

## 7. Review NuGet Package Compatibility

Open the `.csproj` file and review all `<PackageReference>` entries. For any package that targets `net4x` only, locate a compatible version that supports your current TFM. You can check compatibility using:

```bash
dotnet list package --outdated
```

## 8. Publish the Application

Once validation is complete, publish the application for your target platform:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (`linux-x64`, `osx-x64`, etc.) for your deployment target. Review the publish output directory to confirm all required files are present before deploying to the target environment.