# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and test the migrated project before deploying it.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net48`, `netcoreapp`, or any other unintended framework moniker.

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved dependencies.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings that were not surfaced during the initial transformation:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate compatibility issues, such as obsolete API usage or platform-specific calls.

## 4. Run Existing Tests

Execute the test suite to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully. Failures may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Search the codebase for APIs that were available in .NET Framework but are absent or behave differently in cross-platform .NET. Common areas to inspect include:

- `System.Web` references (not available in .NET Core/.NET 5+)
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage
- `BinaryFormatter` (deprecated and disabled by default)
- WCF server-side components

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining issues.

## 6. Validate Runtime Behavior

Run the application manually or through integration tests on each target platform (Windows, Linux, macOS) to confirm consistent behavior. Pay particular attention to:

- File path separators (`/` vs `\`)
- Case sensitivity in file system operations
- Culture and encoding defaults, which may differ between runtimes

## 7. Review Configuration Files

If the project previously used `app.config` or `web.config`, confirm that settings have been migrated to `appsettings.json` or equivalent .NET configuration providers. Verify that connection strings, logging settings, and environment-specific values are correctly loaded at runtime.

## 8. Publish the Application

Once validation is complete, publish the application for the target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` flag (`win-x64`, `osx-x64`, etc.) and `--self-contained` option to match your deployment requirements. Review the output directory to confirm all required assets are present before deploying.