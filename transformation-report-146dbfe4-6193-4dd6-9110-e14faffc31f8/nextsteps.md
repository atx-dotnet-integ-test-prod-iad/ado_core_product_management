# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this is consistent across all projects in the solution.

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore NuGet Packages

Run the following command from the solution root to ensure all dependencies are restored cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version mismatches. Replace any packages that have known .NET-compatible alternatives if warnings are present.

## 3. Build the Solution

Perform a full build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types or obsolete API usage, as these can indicate potential runtime issues.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality behaves as expected after the migration:

```bash
dotnet test --configuration Release
```

Review the test results carefully. Any failing tests should be investigated to determine whether the failure is due to a behavioral difference in the new .NET runtime or a migration issue.

## 5. Validate Runtime Behavior

Run the application locally and exercise the core workflows that were present in the legacy project. Pay particular attention to:

- **Database or ADO.NET interactions** — given the project name `AdoCore`, verify that all data access operations (connections, commands, readers, transactions) function correctly against your target database.
- **Connection strings** — confirm that connection string formats are still valid and that the appropriate database driver NuGet packages (e.g., `Microsoft.Data.SqlClient`) are referenced instead of any legacy `System.Data` providers that may not be fully supported cross-platform.
- **Platform-specific APIs** — check for any code paths that relied on Windows-specific behavior (e.g., registry access, Windows Authentication) and verify they work on your target platform or add appropriate guards.

## 6. Review Configuration Files

Ensure that any `app.config` or `web.config` files have been migrated to `appsettings.json` or equivalent .NET configuration providers. The legacy XML-based configuration system has limited support in cross-platform .NET.

## 7. Check for Implicit Namespace and Nullable Changes

Cross-platform .NET projects enable nullable reference types and implicit usings by default in newer SDK styles. Review the project file for these settings:

```xml
<Nullable>enable</Nullable>
<ImplicitUsings>enable</ImplicitUsings>
```

If these were not present in the original project, they may introduce new compiler warnings or errors that should be resolved before deployment.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target platform:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment target. Review the publish output directory to confirm all required files are present.