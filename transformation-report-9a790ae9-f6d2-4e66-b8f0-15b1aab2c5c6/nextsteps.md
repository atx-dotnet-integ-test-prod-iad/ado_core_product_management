# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this aligns with the runtime environment you intend to deploy to.

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

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate runtime behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Runtime Compatibility Issues

Even with a clean build, certain APIs behave differently or are unavailable at runtime on cross-platform .NET. Pay particular attention to:

- **Windows-specific APIs**: Any usage of `System.Windows.Forms`, `System.Drawing`, `Microsoft.Win32`, or P/Invoke calls may require the `<UseWindowsForms>` or `<UseWPF>` flags, or may not be available on non-Windows platforms.
- **App.config / Web.config**: These are replaced by `appsettings.json` and `Microsoft.Extensions.Configuration` in modern .NET. Verify configuration loading works as expected at runtime.
- **Database and ADO.NET providers**: Since this project is named `AdoCore`, confirm that any database provider NuGet packages (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) are updated to versions compatible with your target framework.

## 5. Review NuGet Package Versions

Open the `.csproj` file and review all `<PackageReference>` entries. Ensure no packages are pinned to versions that only support .NET Framework. Use the following command to check for outdated packages:

```bash
dotnet list package --outdated
```

Update packages where appropriate, then re-run the build and tests.

## 6. Validate Data Access Behavior

Given the ADO-centric nature of this project, perform integration testing against your target database to confirm:

- Connection strings are correctly read from the new configuration system.
- Queries, transactions, and error handling behave as expected.
- Any `DataSet`, `DataTable`, or `DataAdapter` usage functions correctly, as these are supported but carry known behavioral nuances in cross-platform .NET.

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assemblies and configuration files are present before deploying to your target environment.