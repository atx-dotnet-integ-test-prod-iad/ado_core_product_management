# Next Steps

The solution has no build errors following the transformation. Below are steps to validate, test, and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. Run the following to confirm:

```bash
dotnet --version
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any dependency conflicts or packages that could not be resolved. If any packages are flagged as incompatible, check NuGet for updated versions that support the target framework.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review warnings in addition to errors. Some warnings may indicate deprecated APIs or platform-specific code paths that could cause runtime issues.

## 4. Run Existing Tests

If a test project exists in the solution, execute the test suite:

```bash
dotnet test --configuration Release
```

Review test results for any failures. Failures at this stage may indicate behavioral differences between the legacy .NET Framework runtime and the new .NET runtime, such as changes in:

- `System.Data` behavior
- ADO.NET provider APIs
- Exception handling differences

## 5. Validate ADO.NET Functionality

Since the project is named `AdoCore`, it likely contains data access logic. Manually verify the following:

- **Connection strings** are valid and the database provider package (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) is referenced and compatible with the target framework.
- **Database provider registration** is correct. Some providers require explicit registration in .NET that was implicit in .NET Framework.
- **`System.Data` types** such as `DataSet`, `DataTable`, and `DataAdapter` are still available but confirm no removed or changed APIs are in use.

## 6. Check for Platform-Specific Code

Search the codebase for any APIs that are Windows-specific and may not function on Linux or macOS:

- `Registry` access (`Microsoft.Win32.Registry`)
- Windows-only authentication mechanisms (e.g., Windows Integrated Security in connection strings may not work on non-Windows hosts)
- `System.Security.Permissions` attributes, which are no-ops in .NET Core and later

## 7. Run the Application

Execute the application directly to verify runtime behavior:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Test all primary data access paths, including reads, writes, transactions, and error handling scenarios.

## 8. Publish the Application

Once validation is complete, publish the application for deployment:

```bash
dotnet publish --configuration Release --output ./publish
```

To produce a self-contained executable targeting a specific runtime:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (`linux-x64`, `osx-x64`, etc.) based on your deployment target.

## 9. Review Output Artifacts

Inspect the `./publish` directory to confirm all required files, configuration files, and dependencies are present before deploying to the target environment.