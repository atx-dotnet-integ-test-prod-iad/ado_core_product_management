# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy the migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework. Replace any packages that only target `.NET Framework` with their cross-platform equivalents where applicable.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Address any warnings that surface during the build, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify behavioral correctness after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully. Failures may indicate behavioral differences between .NET Framework and cross-platform .NET, such as changes in:

- `System.Drawing` (not fully supported cross-platform without additional packages)
- `System.Data` and ADO.NET provider behavior
- Globalization and culture handling (check if `Invariant Globalization` mode is enabled in the `.csproj`)

## 5. Validate ADO.NET Functionality

Given the project name `AdoCore`, confirm that all database connectivity and data access code functions correctly:

- Verify the database provider package (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) is the correct cross-platform version.
- Test all connection strings, queries, and data operations against a real or local database instance.
- Check for any usage of `System.Data.OleDb` or `System.Data.Odbc`, as these have limited or no cross-platform support.

## 6. Check for Platform-Specific Code

Search the codebase for APIs that may have changed behavior or availability on non-Windows platforms:

- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions (backslashes, drive letters)
- `System.Security.Permissions` and Code Access Security (CAS), which is not enforced in .NET Core and later

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining platform-specific dependencies.

## 7. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

**Framework-dependent deployment:**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained deployment (example for Linux x64):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Review the contents of the `./publish` folder to confirm all required files and dependencies are present before distributing or deploying.