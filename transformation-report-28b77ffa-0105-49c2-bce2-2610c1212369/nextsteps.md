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

Ensure there are no warnings that could indicate deprecated APIs or compatibility shims that may cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify functional correctness:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Runtime Compatibility Issues

Even with a clean build, certain APIs behave differently on cross-platform .NET. Review the following areas manually:

- **Registry access**: `Microsoft.Win32.Registry` is Windows-only. If used, guard with runtime checks or abstract the dependency.
- **`System.Data` and ADO.NET**: Since this project is named `AdoCore`, verify that all database providers (e.g., SQL Server, OLE DB, ODBC) have compatible NuGet packages for .NET. OLE DB and ODBC have limited or no support on non-Windows platforms.
- **`ConfigurationManager`**: If used, ensure the `System.Configuration.ConfigurationManager` NuGet package is referenced.
- **`AppDomain` and Reflection**: Some APIs have been removed or have reduced functionality.

## 5. Validate ADO.NET Provider Compatibility

Given the project name `AdoCore`, confirm that the database drivers in use are compatible with cross-platform .NET:

| Provider | Compatible Package |
|---|---|
| SQL Server | `Microsoft.Data.SqlClient` |
| SQLite | `Microsoft.Data.Sqlite` |
| PostgreSQL | `Npgsql` |
| OLE DB | Windows-only via `System.Data.OleDb` |

If OLE DB or ODBC is in use and cross-platform support is required, plan a migration to a managed provider.

## 6. Test on Target Operating Systems

If cross-platform support is a goal, run the application on each intended OS:

```bash
dotnet run --configuration Release
```

Test on Linux or macOS if applicable, and observe any `PlatformNotSupportedException` errors at runtime.

## 7. Review NuGet Package Versions

Check that all NuGet dependencies are up to date and do not rely on packages that target only `net4x`:

```bash
dotnet list package --outdated
```

Update packages where appropriate, verifying that API surfaces remain compatible.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier:

```bash
# Framework-dependent (requires .NET runtime on target machine)
dotnet publish --configuration Release --output ./publish

# Self-contained (includes the runtime)
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) for your target environment.