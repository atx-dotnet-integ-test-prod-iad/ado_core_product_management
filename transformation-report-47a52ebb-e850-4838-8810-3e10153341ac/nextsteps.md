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

Verify there are no warnings that could indicate deprecated APIs or compatibility issues that were not caught as errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to confirm runtime behavior has not changed after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Runtime-Only Issues

Some APIs behave differently at runtime even when they compile successfully. Pay particular attention to:

- **File path handling**: Legacy code may use hardcoded backslashes (`\`). Use `Path.Combine` or `Path.DirectorySeparatorChar` for cross-platform compatibility.
- **Registry access**: `Microsoft.Win32.Registry` is Windows-only. If the code uses the registry, it will not work on Linux or macOS without conditional compilation or refactoring.
- **Windows-specific APIs**: Any P/Invoke calls or references to `System.Windows.Forms` or `System.Drawing` may require the `-windows` target framework suffix (e.g., `net8.0-windows`) or replacement with cross-platform alternatives.

## 5. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` have versions compatible with the target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update packages where necessary using:

```bash
dotnet add package <PackageName> --version <NewVersion>
```

## 6. Validate ADO.NET or Data Access Behavior

Given the project name `AdoCore`, it likely involves ADO.NET or data access logic. Confirm the following:

- The correct database driver NuGet package is referenced (e.g., `Microsoft.Data.SqlClient` instead of the legacy `System.Data.SqlClient` for SQL Server).
- Connection strings are sourced from configuration (e.g., `appsettings.json`) rather than hardcoded values or `ConfigurationManager`, which behaves differently in .NET Core and later.
- If `ConfigurationManager` is still in use, ensure the `System.Configuration.ConfigurationManager` NuGet package is referenced.

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required files and dependencies are present before deploying to the target environment.