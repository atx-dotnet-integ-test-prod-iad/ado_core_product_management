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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if they do not produce build errors.

## 3. Review NuGet Package Versions

Open the `.csproj` file(s) and check that all `<PackageReference>` entries reference versions compatible with your target framework. Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update packages where appropriate, then rebuild to confirm no new errors are introduced.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework APIs and their cross-platform .NET equivalents.

## 5. Check for Platform-Specific API Usage

Even without build errors, some APIs may have changed behavior on non-Windows platforms. Search the codebase for usages of the following, which are common sources of cross-platform issues:

- `System.Data` and ADO.NET provider-specific code (relevant given the `AdoCore` project name)
- `Registry` access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions (e.g., backslash separators)
- `Thread.Abort()` or `AppDomain` usage

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to assist with this review.

## 6. Validate ADO.NET Database Connectivity

Since this project appears to be ADO.NET-related, confirm that the database driver packages are correctly referenced for cross-platform .NET. For example:

- **SQL Server**: Ensure `Microsoft.Data.SqlClient` is used rather than `System.Data.SqlClient`.
- **Other databases**: Confirm the relevant cross-platform NuGet driver is referenced.

Test actual database connections in a development environment to confirm connectivity and query behavior are correct.

## 7. Run on Target Platform

If the goal is to run on a non-Windows OS, execute the application on that platform explicitly and observe runtime behavior:

```bash
dotnet run --configuration Release
```

Pay particular attention to file I/O, connection strings, and any configuration file paths that may be environment-dependent.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier:

```bash
# Framework-dependent publish
dotnet publish --configuration Release --output ./publish

# Self-contained publish for a specific platform (e.g., Linux x64)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assemblies and configuration files are present before deploying to the target environment.