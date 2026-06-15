# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). For example:

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

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Runtime Compatibility Issues

Even with a clean build, certain APIs behave differently on cross-platform .NET. Review the following areas manually:

- **Registry access** (`Microsoft.Win32.Registry`): Not available on Linux/macOS without the `Microsoft.Win32.Registry` NuGet package.
- **Windows-specific APIs**: Any P/Invoke calls or `System.Drawing` usage may require additional packages or replacements.
- **Configuration**: If the project previously used `System.Configuration.ConfigurationManager`, ensure the `System.Configuration.ConfigurationManager` NuGet package is referenced.
- **Database/ADO.NET**: Since the project is named `AdoCore`, verify that all ADO.NET providers (e.g., `System.Data.SqlClient` vs `Microsoft.Data.SqlClient`) are updated to their cross-platform equivalents.

## 5. Validate NuGet Package Versions

Run the following to check for outdated or deprecated packages:

```bash
dotnet list package --outdated
```

Update packages where appropriate, particularly any that were carried over from the legacy project and may have newer cross-platform compatible versions.

## 6. Perform Functional/Integration Testing

Execute any integration or functional tests against a real data source or environment to confirm end-to-end behavior is consistent with the legacy application. Pay particular attention to:

- Connection string formats
- Transaction handling
- Data type mappings specific to the ADO.NET provider in use

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to ensure all required assemblies and configuration files are present before deploying to the target environment.