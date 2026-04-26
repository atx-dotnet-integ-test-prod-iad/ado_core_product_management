# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to your intended .NET version (e.g., `net8.0` or `net6.0`).

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

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is intact:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Removed or Changed APIs

Cross-platform .NET removes certain APIs that were available in .NET Framework. Run the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` compatibility tool to identify any runtime-level API issues that do not surface as build errors:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to:
- `System.Data` and ADO.NET provider usage, since `AdoCore` suggests database interaction.
- Any usage of `System.Configuration.ConfigurationManager` (requires the `System.Configuration.ConfigurationManager` NuGet package on .NET).
- Platform-specific APIs such as registry access or Windows-only libraries.

## 5. Validate ADO.NET / Database Connectivity

Since the project is named `AdoCore`, verify that database connections function correctly at runtime:

- Confirm that the correct database driver NuGet package is referenced (e.g., `Microsoft.Data.SqlClient` instead of `System.Data.SqlClient` for SQL Server).
- Test connection strings and ensure they are being read correctly from configuration (e.g., `appsettings.json` rather than `app.config` if applicable).
- Execute integration tests or manual queries against a development database to confirm data access works as expected.

## 6. Review NuGet Package Versions

Check that all NuGet dependencies are up to date and compatible with your target framework:

```bash
dotnet list package --outdated
```

Update packages where appropriate, and review release notes for any breaking changes.

## 7. Validate Configuration Loading

If the project previously relied on `app.config` or `web.config`, confirm that configuration has been migrated to `appsettings.json` or environment variables, and that the application reads them correctly using `Microsoft.Extensions.Configuration`.

## 8. Perform Runtime Smoke Testing

Run the application in a development environment and exercise its primary code paths. Check application logs for any runtime exceptions that would not have been caught at compile time.

## 9. Deploy to a Staging Environment

Once local validation is complete:

1. Publish the application using:
   ```bash
   dotnet publish --configuration Release --output ./publish
   ```
2. Deploy the contents of the `./publish` folder to your staging environment.
3. Verify that the application starts and operates correctly against staging resources before promoting to production.