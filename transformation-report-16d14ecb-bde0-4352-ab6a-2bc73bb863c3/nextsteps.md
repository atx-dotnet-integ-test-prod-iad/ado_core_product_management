# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy the migrated project.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net48`, `netcoreapp`, or other legacy monikers unless intentionally targeting multiple frameworks.

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts.

## 3. Build the Solution

Perform a full build to confirm there are no warnings that may indicate compatibility issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to obsolete APIs or platform-specific code paths.

## 4. Run the Test Suite

If the solution contains test projects, execute all tests to verify behavioral correctness after migration:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failed or skipped tests and investigate the root cause of each.

## 5. Check for Platform-Specific Code

Search the codebase for any usage of Windows-specific APIs that may not behave correctly on Linux or macOS, including but not limited to:

- `System.Windows.Forms` or `System.Drawing` (GDI+)
- `Microsoft.Win32` registry access
- COM interop or P/Invoke calls targeting Windows DLLs
- `Environment.SpecialFolder` paths that differ across operating systems

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package where applicable.

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) to confirm consistent behavior. Pay particular attention to:

- File path separators (`\` vs `/`)
- Culture and locale-sensitive formatting
- Configuration file loading (e.g., `app.config` vs `appsettings.json`)

## 7. Review NuGet Package Compatibility

Check that all referenced NuGet packages support the target framework. Use the following command to list outdated packages:

```bash
dotnet list package --outdated
```

Update packages where newer versions provide cross-platform support or resolve known issues.

## 8. Publish the Application

Once validation is complete, publish the application for the desired runtime target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) as needed. Review the publish output directory to confirm all required assets are present.