# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this aligns with the runtime available in your target environment.

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

Verify there are no warnings that could indicate deprecated APIs or compatibility issues that were not surfaced as errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to confirm functional behavior has not changed after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any test failures carefully, as they may indicate behavioral differences between the legacy .NET Framework APIs and their cross-platform .NET equivalents.

## 4. Check for Runtime Compatibility Issues

Some APIs behave differently or are unsupported on non-Windows platforms even when they compile without errors. Pay particular attention to:

- **`System.Drawing`**: Not fully supported cross-platform without additional packages such as `System.Drawing.Common` with native dependencies.
- **Registry access (`Microsoft.Win32.Registry`)**: Only functional on Windows.
- **`AppDomain`**: Some members are no-ops or throw `PlatformNotSupportedException` on non-Windows platforms.
- **COM Interop**: Not supported outside of Windows.

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to surface any remaining platform-specific concerns.

## 5. Review NuGet Package Versions

Confirm all NuGet dependencies reference versions compatible with your target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update packages where appropriate, and verify that no packages still target `net45`, `net472`, or other legacy monikers exclusively.

## 6. Validate Configuration Files

If the project previously relied on `App.config` or `Web.config`, verify that settings have been migrated to `appsettings.json` or the appropriate .NET configuration model. The legacy XML-based configuration system has limited support in cross-platform .NET.

## 7. Test on Target Platform

If the intent is to run on Linux or macOS, perform an explicit test on that operating system:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Then execute the published output on the target machine and verify expected behavior.

## 8. Review Output Type and Entry Point

If `AdoCore` is an executable project, confirm the entry point (`Main` method or top-level statements) is present and correct. If it is a library, confirm the `<OutputType>` is not set to `Exe`.

```xml
<PropertyGroup>
  <OutputType>Library</OutputType>
</PropertyGroup>
```