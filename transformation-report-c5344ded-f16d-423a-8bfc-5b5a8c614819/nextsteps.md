# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and test the migrated project before deploying it.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net4x` or `netstandard` targets unless that is intentional.

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly against the new target framework:

```bash
dotnet restore
```

Review the output for any dependency conflicts or packages that were downgraded.

## 3. Build the Solution

Perform a clean build to confirm there are no warnings that could indicate compatibility issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to deprecated APIs or platform-specific code paths.

## 4. Run Existing Tests

Execute the test suite to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review test results carefully. Any failures that did not exist before the migration should be investigated and resolved before proceeding.

## 5. Check for Platform-Specific Code

Search the codebase for APIs that were Windows-specific in .NET Framework and may behave differently or throw `PlatformNotSupportedException` on non-Windows platforms. Common areas to check include:

- `System.Windows.Forms` or `System.Drawing` usage
- Registry access (`Microsoft.Win32.Registry`)
- `System.Security.Permissions`
- COM interop or P/Invoke calls

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package to identify remaining issues.

## 6. Validate Configuration Files

If the project previously used `app.config` or `web.config`, confirm that settings have been migrated to the appropriate .NET configuration system, such as `appsettings.json` with `Microsoft.Extensions.Configuration`.

## 7. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime. For a self-contained deployment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier for your target environment. Review the publish output directory to confirm all required files are present.

## 9. Review Published Output

Check the published output for any unexpected files or missing dependencies. If you are targeting a framework-dependent deployment, ensure the correct .NET runtime version is installed on the target machine.