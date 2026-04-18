# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If the target framework does not match your intended version, update it and rebuild the solution.

## 2. Restore Dependencies

Run a full NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages and consider updating them to actively maintained versions.

## 3. Build the Solution

Perform a clean build to confirm there are no latent issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Verify that the build output contains no warnings that could indicate compatibility issues, such as obsolete API usage or platform-specific calls.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully. Failures may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime, particularly around areas such as:

- `System.Data` and ADO.NET provider behavior
- Connection string formats
- Exception types and messages
- Culture and encoding defaults

## 5. Validate ADO.NET Database Connectivity

Since the project is named `AdoCore`, it likely involves database access. Verify the following:

- The correct database provider NuGet package is referenced (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`).
- Connection strings are valid and accessible in the target environment.
- Any use of `System.Data.OleDb` or `System.Data.Odbc` is reviewed, as these have limited or no support on non-Windows platforms.

Test actual database connections against a known-good data source to confirm queries execute and return expected results.

## 6. Check for Platform-Specific Code

Search the codebase for any remaining Windows-specific APIs that may compile successfully but fail at runtime on Linux or macOS:

- Registry access (`Microsoft.Win32.Registry`)
- Windows Authentication / SSPI
- COM interop
- `System.Data.OleDb` (Windows-only)

Replace or conditionally compile any such code if cross-platform execution is required.

## 7. Review Configuration and App Settings

Ensure that any configuration files (e.g., `appsettings.json`, environment variables) are correctly structured for the .NET configuration system (`Microsoft.Extensions.Configuration`) rather than relying on `App.config` or `Web.config` patterns from .NET Framework.

## 8. Test on Target Operating Systems

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime-only platform issues that do not appear at compile time.

## 9. Publish the Application

Once validation is complete, publish the application for the target environment:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value, for example:

- `win-x64` for Windows
- `linux-x64` for Linux
- `osx-x64` for macOS

Review the publish output directory to confirm all required files and dependencies are present before deploying.