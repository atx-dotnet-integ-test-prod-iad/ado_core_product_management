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

Verify that no warnings are being treated as errors and that all projects compile cleanly.

## 3. Review Removed or Replaced APIs

Check that any APIs that were previously Windows-specific (e.g., from `System.Web`, `Microsoft.Win32`, or COM interop) have been replaced with cross-platform equivalents. Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) if needed.

## 4. Run Existing Tests

If the solution contains test projects, execute them to confirm existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and modern .NET.

## 5. Validate Runtime Behavior

Run the application locally and exercise its primary functionality. Pay particular attention to:

- File I/O paths, as path separators differ between Windows and Unix-based systems.
- Configuration loading (e.g., `app.config` replaced by `appsettings.json` or environment variables).
- Any reflection-based code, which may behave differently under the new runtime.

## 6. Check NuGet Package Compatibility

Review all NuGet dependencies in `AdoCore.csproj` and confirm each package supports the target framework. Packages that only supported .NET Framework may need to be updated or replaced.

```bash
dotnet list package --outdated
```

Update packages where applicable:

```bash
dotnet add package <PackageName> --version <LatestVersion>
```

## 7. Cross-Platform Smoke Test

If cross-platform support is a goal, run the application on a non-Windows OS (Linux or macOS) to surface any remaining platform-specific issues that do not manifest on Windows.

## 8. Review Output and Publish

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the contents of the `./publish` directory and confirm the output runs correctly in the target environment.