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

Check all NuGet dependencies in `AdoCore.csproj` to confirm they reference versions compatible with the target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any outdated packages as appropriate.

## 4. Check for Removed or Changed APIs

Review the code for any usage of APIs that were available in .NET Framework but have changed or been removed in cross-platform .NET. Common areas to check include:

- `System.Web` references (not available in cross-platform .NET)
- `AppDomain` usage
- Windows-specific registry or file path assumptions
- `ConfigurationManager` (requires the `System.Configuration.ConfigurationManager` NuGet package)

## 5. Run Existing Tests

If the solution contains a test project, execute the test suite to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release
```

Review any failing tests to determine whether they indicate a behavioral difference introduced by the migration.

## 6. Validate ADO-Specific Functionality

Since this project is named `AdoCore`, it likely involves data access. Manually verify the following:

- Database connection strings are correctly configured for the new environment.
- Any `System.Data` or ADO.NET usage functions correctly against the target database.
- Connection string sources (e.g., `appsettings.json` vs. `app.config`) are appropriate for cross-platform .NET.

## 7. Run the Application

Execute the application directly to confirm it starts and operates correctly:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Test all major code paths, particularly those involving database reads and writes.

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value for your target platform, for example:

- `win-x64` for Windows
- `linux-x64` for Linux
- `osx-x64` for macOS

The published output will be located in the `bin/Release/<framework>/<runtime>/publish/` directory and can be deployed to the target environment.