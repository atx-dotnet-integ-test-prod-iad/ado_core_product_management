# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this is consistent with any dependent or consuming projects in the solution.

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

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not cause build failures.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior matches expectations after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding. Pay particular attention to tests covering data access, as ADO.NET behavior can differ subtly between .NET Framework and cross-platform .NET.

## 4. Validate ADO.NET Database Connectivity

Since the project name suggests ADO.NET usage (`AdoCore`), verify that database connections function correctly on the target platform:

- Confirm the database provider NuGet package is the correct cross-platform version (e.g., `Microsoft.Data.SqlClient` instead of `System.Data.SqlClient` for SQL Server).
- Test connection strings, especially if they previously relied on Windows-integrated security or SSPI, as these may require adjustment in non-Windows environments.
- Verify that any `DataSet`, `DataTable`, or `DataAdapter` usage behaves as expected under the new runtime.

## 5. Review Configuration Files

Check that any configuration previously stored in `App.config` or `Web.config` has been migrated to `appsettings.json` or environment variables, as `System.Configuration.ConfigurationManager` has limited support in cross-platform .NET without the `System.Configuration.ConfigurationManager` NuGet package.

## 6. Check for Platform-Specific Code

Search the codebase for any remaining Windows-specific APIs that may compile successfully but fail at runtime on Linux or macOS:

- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific security APIs
- COM interop

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify these if needed.

## 7. Perform Runtime Smoke Testing

Run the application in a representative environment and exercise the primary code paths manually or through integration tests to confirm there are no runtime exceptions that were not caught at compile time.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate RID (e.g., `linux-x64`, `osx-x64`) if deploying to a non-Windows environment. Review the contents of the `publish` output folder to confirm all required assemblies and configuration files are present.