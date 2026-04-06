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

If the solution contains test projects, execute them to verify that runtime behavior has not changed after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Runtime-Only Issues

Some issues do not surface at build time. Pay attention to the following areas:

- **`System.Configuration`**: If the project previously used `App.config` or `ConfigurationManager`, ensure you have added the `System.Configuration.ConfigurationManager` NuGet package and migrated settings where appropriate.
- **`System.Data` / ADO.NET**: Since the project is named `AdoCore`, verify that all ADO.NET data provider packages (e.g., `Microsoft.Data.SqlClient`) are explicitly referenced, as some providers are no longer included by default.
- **Platform-specific APIs**: Run the application on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement.

## 5. Review NuGet Package Compatibility

Run the following command to check for any outdated or vulnerable packages:

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

Update packages as needed using:

```bash
dotnet add package <PackageName> --version <LatestVersion>
```

## 6. Validate ADO.NET Functionality

Given the project name, manually verify the following ADO.NET-related behaviors at runtime:

- Database connections open and close correctly.
- Queries return expected results.
- Transactions commit and roll back as expected.
- Connection strings are being read correctly from the new configuration system (e.g., `appsettings.json` via `Microsoft.Extensions.Configuration` rather than `App.config`).

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assemblies and configuration files are present before deploying to the target environment.