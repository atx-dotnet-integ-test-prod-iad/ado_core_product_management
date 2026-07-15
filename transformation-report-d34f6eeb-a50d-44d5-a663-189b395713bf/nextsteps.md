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

Review any test failures carefully, as they may indicate behavioral differences introduced by the migration to cross-platform .NET.

## 4. Validate Data Access Behavior

Since the project is named `AdoCore`, it likely involves ADO.NET data access. Verify the following:

- Connection strings are correctly configured for the target environment, particularly if the legacy project used Windows-specific authentication (e.g., `Integrated Security=True`). This may not function as expected on non-Windows platforms.
- Any use of `System.Data.OleDb` or `System.Data.Odbc` should be reviewed, as these have platform limitations on Linux and macOS.
- If SQL Server is the target database, confirm the `Microsoft.Data.SqlClient` NuGet package is being used rather than the older `System.Data.SqlClient`.

## 5. Check for Platform-Specific Code

Search the codebase for any remaining platform-specific APIs that may compile successfully but fail at runtime on non-Windows systems:

- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions (backslashes, drive letters)
- `System.Drawing` usage (requires additional native dependencies on Linux)

Use the .NET Compatibility Analyzer or the `dotnet-compatibility` tool to assist with this review:

```bash
dotnet tool install -g dotnet-compatibility
```

## 6. Review Configuration Files

Ensure that any configuration previously held in `App.config` or `Web.config` has been migrated to `appsettings.json` or environment variables, as the legacy XML-based configuration system has limited support in modern .NET.

## 7. Publish the Application

Once validation is complete, publish the application for your target environment:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) if deploying to a non-Windows environment. Review the contents of the `publish` output directory before deploying to confirm all required assets are present.