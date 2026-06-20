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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Review NuGet Package Versions

Check that all NuGet dependencies referenced in `AdoCore.csproj` are targeting versions compatible with your chosen .NET version. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any outdated packages as appropriate using:

```bash
dotnet add package <PackageName> --version <NewVersion>
```

## 4. Check for Removed or Changed APIs

Some APIs available in .NET Framework are not present or have changed in cross-platform .NET. Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the [Platform Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to identify any runtime-level compatibility concerns that do not surface as build errors.

## 5. Run Existing Tests

If the solution contains a test project, execute the test suite to verify functional correctness:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address regressions that may have been introduced during the migration.

## 6. Validate Runtime Behavior

Run the application locally and exercise its primary workflows, particularly any that rely on:

- File system access (path separators differ between Windows and Linux/macOS)
- Registry access (not available on non-Windows platforms)
- Windows-specific APIs or P/Invoke calls
- Database connectivity (if ADO.NET is in use, given the project name `AdoCore`)

For database-related functionality specifically, verify that the ADO.NET provider being used (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, etc.) is correctly configured and connecting as expected in the new environment.

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assemblies and configuration files are present before deploying to the target environment.