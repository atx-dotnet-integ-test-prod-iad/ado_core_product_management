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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding further.

## 4. Check for Removed or Changed APIs

Even without build errors, some APIs behave differently in cross-platform .NET compared to .NET Framework. Pay particular attention to:

- **`System.Data`** and ADO.NET provider usage, since `AdoCore` implies database interaction. Verify that the database provider NuGet packages (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) are explicitly referenced and up to date.
- Any use of `System.Configuration.ConfigurationManager` — this requires the `System.Configuration.ConfigurationManager` NuGet package on cross-platform .NET.
- `DataSet`, `DataTable`, and `DataAdapter` usage, which are supported but may have behavioral differences.

## 5. Validate NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` are compatible with your target framework:

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

Update any outdated or vulnerable packages as appropriate.

## 6. Test on Target Operating Systems

If cross-platform support is a goal, run the application and its tests on each target OS (Windows, Linux, macOS) to catch platform-specific issues such as:

- File path separator differences (`\` vs `/`)
- Case-sensitive file systems on Linux
- Platform-specific database driver behavior

## 7. Review Runtime Configuration

Ensure `appsettings.json` or equivalent configuration files are present and correctly structured, replacing any legacy `App.config` or `Web.config` entries where applicable.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assets and dependencies are present before deploying to the target environment.