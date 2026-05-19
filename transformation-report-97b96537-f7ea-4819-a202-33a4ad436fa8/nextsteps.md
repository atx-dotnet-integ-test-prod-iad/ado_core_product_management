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

Review the output for any warnings that may indicate deprecated APIs or packages that were not caught as errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any test failures before proceeding.

## 4. Check for Removed or Changed APIs

Review any usage of APIs that were available in .NET Framework but have changed or been removed in .NET. The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.UpgradeAssistant` tool can assist with identifying these at the code level.

Pay particular attention to:
- `System.Web` dependencies (not available in .NET Core/.NET 5+)
- Windows-only APIs (e.g., registry access, WCF server-side, Windows Forms)
- Any use of `AppDomain`, `BinaryFormatter`, or `Remoting`

## 5. Validate NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` are compatible with your target framework. You can inspect this in the project file or by running:

```bash
dotnet list package --outdated
```

Replace any packages that do not support the target framework with their modern equivalents.

## 6. Verify ADO.NET Functionality

Since the project is named `AdoCore`, it likely contains data access logic. Confirm the following:

- Connection strings are correctly configured for the target environment (check `appsettings.json` or environment variables rather than `app.config` or `web.config`).
- Any `System.Data` or `Microsoft.Data.SqlClient` references are using the correct and up-to-date package versions.
- Database connectivity works as expected by running integration or smoke tests against a known-good database instance.

## 7. Review Configuration Migration

If the original project used `app.config` or `web.config`, verify that configuration values have been moved to the appropriate .NET configuration system (e.g., `appsettings.json`, environment variables, or `IConfiguration`).

## 8. Perform a Runtime Smoke Test

Run the application against a representative workload or dataset and verify that outputs match the expected results from the legacy version. Compare behavior between the old and new versions where possible.

## 9. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files and dependencies are present before deploying to the target environment.