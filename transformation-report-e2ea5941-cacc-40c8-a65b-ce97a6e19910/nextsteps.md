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

Review the output for any warnings about deprecated packages or packages that do not support your target framework. If any packages are flagged, check NuGet.org for updated versions that support the new TFM.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review the build output for any warnings, particularly those related to obsolete APIs or platform-specific calls that may not behave as expected on non-Windows platforms.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as failures may indicate behavioral differences between the legacy .NET Framework runtime and the new .NET runtime.

## 5. Check for Windows-Specific API Usage

Even without build errors, the code may reference APIs that are only functional on Windows. Use the .NET Compatibility Analyzer to surface these at build time by adding the following to `AdoCore.csproj`:

```xml
<PropertyGroup>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <AnalysisMode>All</AnalysisMode>
</PropertyGroup>
```

Rebuild and review any new analyzer warnings, particularly `CA1416` (platform compatibility).

## 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that static analysis may not catch.

## 7. Review Configuration Files

Legacy projects often rely on `App.config` or `Web.config`. Confirm that any configuration has been migrated to `appsettings.json` or the appropriate .NET configuration provider, and that the application reads configuration correctly at runtime.

## 8. Publish the Application

Once validation is complete, publish the application for your target environment:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value, for example `win-x64`, `linux-x64`, or `osx-x64`. Review the contents of the publish output folder to confirm all required assets are present before deploying.