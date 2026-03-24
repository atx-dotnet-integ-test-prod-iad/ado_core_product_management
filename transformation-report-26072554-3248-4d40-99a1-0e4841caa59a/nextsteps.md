# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. You can check your installed SDKs by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version mismatches, and update any packages that have known replacements for modern .NET.

## 3. Build the Solution

Perform a full build in Release configuration to confirm there are no errors or warnings that may have been suppressed in Debug mode:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or obsolete API usage.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated to determine whether they indicate a regression introduced by the migration.

## 5. Validate Platform-Specific Code

Review the codebase for any APIs that were previously Windows-specific and may now behave differently or throw `PlatformNotSupportedException` on non-Windows platforms. Common areas to check include:

- Registry access (`Microsoft.Win32.Registry`)
- Windows Event Log (`System.Diagnostics.EventLog`)
- Windows Communication Foundation (WCF) server-side APIs
- `System.Drawing` (GDI+) usage

If cross-platform support is required, replace these with supported alternatives or add platform guards using `RuntimeInformation.IsOSPlatform`.

## 6. Check for Removed or Changed APIs

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any APIs that were available in .NET Framework but have been removed or changed in modern .NET:

```bash
dotnet tool install -g dotnet-compatibility
```

## 7. Test on Target Platforms

If the goal is cross-platform support, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a build.

## 8. Review Configuration and App Settings

Confirm that configuration files have been migrated appropriately. `app.config` and `web.config` files are not fully supported in modern .NET. Migrate settings to `appsettings.json` and use the `Microsoft.Extensions.Configuration` libraries where applicable.

## 9. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier for your deployment target (e.g., `win-x64`, `osx-x64`). Review the contents of the publish output directory before deploying to confirm all required files are present.