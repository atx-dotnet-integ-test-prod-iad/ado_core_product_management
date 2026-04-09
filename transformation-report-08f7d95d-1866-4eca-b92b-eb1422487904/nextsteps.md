# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-specific framework such as `net48`, update it accordingly.

## 2. Restore Dependencies

Run a full NuGet restore to ensure all packages resolve correctly against the new target framework:

```bash
dotnet restore
```

Review the output for any dependency conflicts or packages that could not be resolved.

## 3. Build the Solution

Perform a clean build to confirm there are no lingering issues:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types or deprecated APIs, as these can indicate areas that may cause runtime issues.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior has been preserved after the migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully. Failures may indicate behavioral differences between .NET Framework and cross-platform .NET, particularly around areas such as:

- `System.Data` and ADO.NET provider behavior
- File path handling (`Path.DirectorySeparatorChar`)
- Culture and encoding defaults
- Reflection behavior changes

## 5. Validate ADO.NET Data Provider Compatibility

Since the project is named `AdoCore`, it likely involves ADO.NET data access. Verify the following:

- The database provider NuGet package (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) is explicitly referenced and is a version compatible with cross-platform .NET.
- Connection strings are still valid and accessible in the new runtime environment.
- Any use of `System.Data.OleDb` or `System.Data.Odbc` is reviewed, as these have platform-specific limitations on non-Windows operating systems.

## 6. Check for Platform-Specific Code

Search the codebase for APIs that are Windows-only and may not function on Linux or macOS:

- `Registry` access (`Microsoft.Win32.Registry`)
- `System.Drawing` (requires `libgdiplus` on Linux or migration to an alternative)
- COM interop
- Windows Event Log

These will compile successfully but may throw `PlatformNotSupportedException` at runtime on non-Windows platforms.

## 7. Run on Target Platform

If the goal is to run on a non-Windows platform, execute the application on that platform directly to catch any runtime issues not surfaced during the build:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application for the target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` identifier (`linux-x64`, `win-x64`, `osx-x64`, etc.) and `--self-contained` flag based on your deployment requirements. A self-contained deployment (`--self-contained true`) bundles the .NET runtime and removes the dependency on a pre-installed runtime on the target machine.