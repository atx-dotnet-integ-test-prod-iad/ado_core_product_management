# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

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

Review the output for any warnings that could indicate deprecated APIs or compatibility concerns, even if they do not block the build.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Runtime-Only Issues

Some issues do not surface at build time but appear at runtime. Exercise the main execution paths of the application manually or through integration tests. Pay particular attention to:

- **File I/O paths**: Windows-style paths (e.g., backslashes) may behave differently on Linux/macOS.
- **Registry access**: `Microsoft.Win32.Registry` is not available on non-Windows platforms.
- **Windows-specific APIs**: Any P/Invoke calls or APIs under `System.Windows` namespaces will not function on non-Windows systems.
- **Configuration files**: Ensure `app.config` or `web.config` settings have been migrated to `appsettings.json` or equivalent if applicable.

## 5. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` have versions that support the target framework. You can inspect this with:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with cross-platform support.

## 6. Validate ADO.NET Data Access

Since the project name suggests ADO.NET usage (`AdoCore`), verify the following:

- The database driver package (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) targets the correct framework and is up to date.
- Connection strings are correctly sourced from configuration rather than hardcoded values.
- Any use of `System.Data.OleDb` is replaced, as it is Windows-only.

## 7. Publish the Application

Once validation is complete, publish the application for the target platform:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value, such as `win-x64`, `linux-x64`, or `osx-x64`. Use `--self-contained true` if you want to bundle the .NET runtime with the output.

## 8. Verify Published Output

Navigate to the publish output directory and confirm all expected assemblies, configuration files, and dependencies are present before deploying to the target environment.