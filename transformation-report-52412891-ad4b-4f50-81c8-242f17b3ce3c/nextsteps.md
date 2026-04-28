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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

## 3. Review NuGet Package Versions

Open the `.csproj` file and check that all `<PackageReference>` entries reference versions compatible with the target framework. Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions available, particularly those that were previously tied to .NET Framework.

## 4. Check for Removed or Changed APIs

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.ApiCompat` tool to identify any API usage that may have been available in .NET Framework but is absent or changed in cross-platform .NET:

```bash
dotnet tool install -g dotnet-upgrade-assistant
dotnet-upgrade-assistant analyze
```

Pay particular attention to:
- `System.Data` and ADO.NET-related APIs (given the project name `AdoCore`)
- Any database provider packages (e.g., `System.Data.SqlClient` should be replaced with `Microsoft.Data.SqlClient`)

## 5. Run Existing Tests

If a test project exists in the solution, execute the tests to validate runtime behavior:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output for any failures and address them before proceeding.

## 6. Manual Functional Validation

Since this project appears to be ADO.NET related, manually verify the following at runtime:

- Database connections open and close correctly.
- Queries return expected results.
- Transactions commit and roll back as expected.
- Any connection string configuration has been moved to the appropriate `appsettings.json` or environment variable pattern, replacing any legacy `app.config` or `web.config` entries.

## 7. Check Configuration Files

If the original project used `app.config` for connection strings or settings, ensure these have been migrated to `appsettings.json` and are being read via `Microsoft.Extensions.Configuration`:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "your-connection-string-here"
  }
}
```

## 8. Publish the Project

Once validation is complete, publish the project using:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the contents of the `./publish` directory to ensure all required assemblies and configuration files are present before deploying to the target environment.