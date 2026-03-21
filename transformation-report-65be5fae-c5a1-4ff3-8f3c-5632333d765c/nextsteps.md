# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build context:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types, obsolete APIs, or platform compatibility.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Verify Platform-Specific Code

Inspect the codebase for any APIs that were available in .NET Framework but have limited or no support in cross-platform .NET. Common areas to check include:

- `System.Web` usage
- Windows Registry access (`Microsoft.Win32.Registry`)
- WCF server-side components
- `AppDomain` usage beyond what is supported
- `BinaryFormatter` serialization (deprecated and disabled by default)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package to surface any remaining compatibility issues.

## 5. Run the Application and Perform Smoke Testing

Start the application and manually verify that core workflows function as expected:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Pay particular attention to database connectivity, file I/O paths, and any configuration values that may have been sourced from `app.config` or `web.config`, as these are handled differently under the new `Microsoft.Extensions.Configuration` model.

## 6. Review Configuration Migration

If the project previously relied on `app.config` or `web.config`, confirm that settings have been correctly migrated to `appsettings.json` or environment variables. Verify that connection strings and application settings are being read correctly at runtime.

## 7. Publish the Application

Once validation is complete, publish the application for your target environment:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier for your target platform (e.g., `linux-x64`, `osx-x64`).

## 8. Validate the Published Output

Navigate to the publish output directory and run the application from there to confirm the published artifacts behave identically to the development build:

```bash
cd ./publish
./AdoCore
```

Confirm that all configuration files, static assets, and dependencies are present in the output directory.