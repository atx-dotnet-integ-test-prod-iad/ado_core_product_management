# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

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

Review the output for any warnings that could indicate deprecated APIs or packages that may cause runtime issues even if they do not produce build errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Runtime-Only Issues

Some issues do not surface at build time. Pay attention to the following areas:

- **`System.Configuration`**: If the project previously used `App.config` or `ConfigurationManager`, ensure you have added the `System.Configuration.ConfigurationManager` NuGet package and migrated settings where appropriate.
- **`System.Data` / ADO.NET**: Since this project appears to be ADO.NET-related (`AdoCore`), verify that all database providers (e.g., `System.Data.SqlClient` vs `Microsoft.Data.SqlClient`) are referencing the correct cross-platform compatible packages.
- **Platform-specific APIs**: Any use of Windows Registry, COM interop, or Windows-only APIs will fail at runtime on non-Windows platforms even if they compile successfully.

## 5. Validate Database Connectivity

Given the ADO.NET nature of this project, perform an integration test against the target database to confirm:

- Connection strings are correctly configured for the new environment.
- All queries, stored procedure calls, and transactions behave as expected.
- Any `DataAdapter`, `DataSet`, or `DataReader` usage returns correct results.

## 6. Review NuGet Package Compatibility

Run the following command to check for outdated or deprecated packages:

```bash
dotnet list package --outdated
dotnet list package --deprecated
```

Update packages as needed, prioritizing any that are marked deprecated, as they may have known compatibility issues with modern .NET.

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required assemblies and configuration files are present before deploying to the target environment.