# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

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

Review the output for any warnings that may indicate deprecated APIs or platform-specific code paths that could cause runtime issues even if they do not produce build errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been silently replaced or may behave differently on non-Windows platforms. Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for platform-specific calls:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze ./AdoCore.csproj
```

Pay particular attention to:
- `System.Data` and ADO.NET provider usage, as some providers require explicit NuGet packages in .NET
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions

## 5. Validate ADO.NET Database Connectivity

Since the project is named `AdoCore`, it likely involves database access. Confirm that the appropriate database driver NuGet package is referenced explicitly, as .NET no longer includes drivers like SQL Server in the base framework:

| Database | Required NuGet Package |
|---|---|
| SQL Server | `Microsoft.Data.SqlClient` |
| SQLite | `Microsoft.Data.Sqlite` |
| PostgreSQL | `Npgsql` |
| MySQL | `MySql.Data` or `Pomelo.EntityFrameworkCore.MySql` |

Verify connection strings are still valid and that any configuration previously stored in `app.config` has been migrated to `appsettings.json` or environment variables if applicable.

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime-only platform issues:

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
# Framework-dependent (requires .NET runtime installed on target machine)
dotnet publish --configuration Release --output ./publish

# Self-contained (bundles the runtime)
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Review the contents of the `./publish` directory to confirm all expected files and dependencies are present before deploying.