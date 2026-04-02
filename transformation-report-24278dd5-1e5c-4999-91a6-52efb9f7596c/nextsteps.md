# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this aligns with the runtime version available in your target environment.

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

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not cause build failures.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations from the legacy project:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Pay close attention to any tests that interact with database connections, file I/O, or platform-specific APIs, as these are common sources of cross-platform issues.

## 4. Validate ADO.NET Functionality

Since the project is named `AdoCore`, it likely contains ADO.NET data access code. Verify the following:

- The correct database driver NuGet package is referenced (e.g., `Microsoft.Data.SqlClient` for SQL Server, `Npgsql` for PostgreSQL, `MySql.Data` for MySQL).
- Connection strings are not hardcoded and are being read from `appsettings.json` or environment variables, rather than from `app.config` or `web.config` which are not fully supported in the same way on cross-platform .NET.
- Any use of `System.Data.OleDb` or `System.Data.Odbc` is reviewed, as these namespaces have limited or no support on non-Windows platforms.

## 5. Check for Platform-Specific Code

Search the codebase for APIs that may only function on Windows:

- `Microsoft.Win32` namespace usage
- `Registry` access
- `System.Drawing` (use `System.Drawing.Common` with awareness of its Windows-only limitations on .NET 6+)
- COM interop or P/Invoke calls targeting Windows-specific libraries

If cross-platform support is required, these areas will need to be refactored or conditionally compiled.

## 6. Review NuGet Package Compatibility

Run the following command to check for any outdated or incompatible packages:

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

Update packages where appropriate, particularly any that were carried over from the legacy .NET Framework project.

## 7. Test on Target Operating Systems

If the goal is cross-platform support, run the application on each intended operating system (Windows, Linux, macOS) and verify behavior is consistent, particularly around:

- File path separators
- Case sensitivity in file system operations
- Culture and encoding defaults

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory and confirm all required assets, configuration files, and dependencies are present before deploying to the target environment.