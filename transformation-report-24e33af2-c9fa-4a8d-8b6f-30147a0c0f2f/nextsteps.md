# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework is set to the intended cross-platform version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts that may not have surfaced as build errors.

## 3. Build the Solution

Perform a full build in Release configuration to confirm there are no configuration-specific issues:

```bash
dotnet build --configuration Release
```

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify behavioral correctness after migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate runtime behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Even without build errors, some APIs that compiled successfully may throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Run the build again and review any new analyzer warnings.

## 6. Run the Application

Execute the application directly to observe runtime behavior:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Test all major code paths, particularly any that involve:
- Database access (ADO.NET connections, drivers, connection strings)
- File system operations
- Registry access (not supported cross-platform)
- Windows-specific authentication

## 7. Validate ADO.NET Connectivity

Given the project name `AdoCore`, confirm that your database driver NuGet package is compatible with the target framework. For example:

- **SQL Server**: `Microsoft.Data.SqlClient`
- **SQLite**: `Microsoft.Data.Sqlite`
- **PostgreSQL**: `Npgsql`

Verify connection strings and authentication mechanisms work correctly in the new runtime environment.

## 8. Review Removed or Changed APIs

Consult the official .NET migration guide for any APIs that were removed or changed from .NET Framework:

- [https://learn.microsoft.com/en-us/dotnet/core/compatibility/](https://learn.microsoft.com/en-us/dotnet/core/compatibility/)

Pay particular attention to breaking changes in the version range spanning your original .NET Framework version and your new target.

## 9. Publish the Application

Once validation is complete, publish the application for your target platform:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) depending on your deployment target. Review the output in the `publish` folder before deploying.