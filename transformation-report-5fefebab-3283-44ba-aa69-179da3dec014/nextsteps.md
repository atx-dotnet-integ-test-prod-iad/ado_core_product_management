# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on all machines that will build or run this project.

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not support the target framework or that have been replaced by inbox .NET APIs.

## 3. Build the Solution

Perform a clean build to confirm there are no residual or environment-specific issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to deprecated APIs or platform compatibility analyzers (CA1416, etc.).

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify behavioral correctness after migration:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` result files for any failing or skipped tests. Pay particular attention to tests that exercise data access, file I/O, or platform-specific code paths, as these are common areas affected by cross-platform migration.

## 5. Check for Platform-Specific API Usage

Run the .NET Compatibility Analyzer or the `dotnet-compatibility` tool to surface any remaining platform-specific API calls that may compile successfully but fail at runtime on non-Windows platforms:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Review analyzer warnings in your IDE or build output and replace or conditionally compile any flagged APIs.

## 6. Validate ADO / Data Access Behavior

Since the project is named `AdoCore`, verify that all ADO.NET connection strings, provider registrations, and database driver packages are compatible with cross-platform .NET. Specifically:

- Confirm that the database driver NuGet package (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) targets `netstandard2.0` or `net6.0+`.
- Test connection and query execution against your target database from a non-Windows environment if cross-platform support is a requirement.
- Check that any `System.Data.OleDb` or `System.Data.Odbc` usage has been replaced or wrapped, as these have limited or no support outside of Windows.

## 7. Review Configuration and File Paths

Ensure that any hardcoded file paths use `Path.Combine` or `Path.DirectorySeparatorChar` rather than backslash literals, and that configuration files (e.g., `appsettings.json`) are correctly copied to the output directory:

```xml
<ItemGroup>
  <None Update="appsettings.json">
    <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
  </None>
</ItemGroup>
```

## 8. Publish the Application

Once validation is complete, publish the application for your target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` identifier (RID) to match your deployment target (e.g., `win-x64`, `osx-x64`, `linux-arm64`). Review the publish output directory to confirm all required assets are present before deploying.