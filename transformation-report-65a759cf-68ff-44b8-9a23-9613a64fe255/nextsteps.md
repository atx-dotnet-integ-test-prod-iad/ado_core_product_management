# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-only TFM such as `net472` or `net48`, update it accordingly.

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or compatibility issues that did not surface as hard errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any test failures carefully, as they may indicate behavioral differences introduced by the framework migration.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been replaced with cross-platform alternatives that behave differently at runtime. Review usage of the following areas if they are present in the codebase:

- `System.Data` and ADO.NET provider registrations (relevant given the `AdoCore` project name)
- `System.Configuration.ConfigurationManager` (requires the `System.Configuration.ConfigurationManager` NuGet package on .NET Core/5+)
- File path handling (`Path.Combine` vs hardcoded separators)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific authentication or security APIs

## 5. Validate ADO.NET Database Connectivity

Since this project is named `AdoCore`, verify that database connections function correctly at runtime:

- Confirm the correct database provider NuGet package is referenced (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`)
- Ensure connection strings are being read from the correct configuration source (`appsettings.json` rather than `app.config` or `web.config` where applicable)
- Test actual query execution against a development database instance

## 6. Review NuGet Package Compatibility

Run the following command to check for any packages that may not fully support your target framework:

```bash
dotnet list package --outdated
dotnet list package --deprecated
```

Update any flagged packages to versions that explicitly support the target TFM.

## 7. Run on Target Operating System

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime-only platform compatibility issues.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the output directory to confirm all required assets and dependencies are present before deploying to the target environment.