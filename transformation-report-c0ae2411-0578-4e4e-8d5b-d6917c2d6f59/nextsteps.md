# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`).

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Review NuGet Package Versions

Check that all NuGet dependencies referenced in `AdoCore.csproj` are compatible with the target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework.

## 4. Check for Removed or Changed APIs

Review the code for any usage of APIs that were available in .NET Framework but have changed or been removed in cross-platform .NET. The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.UpgradeAssistant` tool can help identify these at the code level.

## 5. Run Existing Tests

If the solution contains a test project, execute the tests to validate runtime behavior:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests to determine whether they reflect regressions introduced during migration or pre-existing issues.

## 6. Validate Platform-Specific Behavior

Since this is a cross-platform migration, run the application on each target operating system (Windows, Linux, macOS) where applicable. Pay particular attention to:

- File path separators (`\` vs `/`)
- Registry access (not available on Linux/macOS)
- Windows-specific APIs (e.g., `System.Drawing`, certain `System.Runtime.InteropServices` calls)
- Case sensitivity in file system operations

## 7. Check Runtime Configuration Files

Ensure that `appsettings.json`, `runtimeconfig.json`, or any other configuration files are present and correctly structured for the new runtime. Verify that connection strings and environment-specific settings are accurate.

## 8. Perform a Release Build and Smoke Test

Publish the application and run a basic smoke test against the published output:

```bash
dotnet publish --configuration Release --output ./publish
```

Then execute the published binary directly to confirm it runs as expected outside of the development environment.

## 9. Review Warnings in Build Output

Even without errors, review the full build output for warnings (`CS0618`, `CS0obsolete`, platform compatibility warnings such as `CA1416`, etc.). Address these warnings to reduce the risk of future runtime failures.