# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework is set to a supported cross-platform .NET version (e.g., `net6.0`, `net7.0`, or `net8.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing `net48` or any other .NET Framework moniker, update it accordingly.

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about packages that may not be fully compatible with the target framework.

## 3. Build the Solution

Perform a full build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to deprecated APIs or platform compatibility.

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests and determine whether they are caused by behavioral differences between .NET Framework and cross-platform .NET.

## 5. Check for Windows-Specific API Usage

Even without build errors, some APIs may compile successfully but fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these issues:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Pay particular attention to any usage of:
- `System.Data` providers that rely on Windows-specific drivers
- `Microsoft.Win32` namespaces
- COM interop or P/Invoke calls targeting Windows libraries

## 6. Runtime Validation

Run the application on each target platform (Windows, Linux, macOS) to confirm runtime behavior is consistent:

```bash
dotnet run --configuration Release
```

If the project is a library, write or run integration tests that exercise the public API surface on each platform.

## 7. Review ADO.NET Data Provider References

Given the project name (`AdoCore`), confirm that any ADO.NET data providers referenced (e.g., SQL Server, Oracle, MySQL) have cross-platform compatible NuGet packages:

| Legacy Reference | Cross-Platform Replacement |
|---|---|
| `System.Data.SqlClient` | `Microsoft.Data.SqlClient` |
| Oracle ODP.NET (legacy) | `Oracle.ManagedDataAccess.Core` |
| MySQL Connector (legacy) | `MySql.Data` or `MySqlConnector` |

Update the `.csproj` package references and any connection or factory initialization code accordingly.

## 8. Publish the Application

Once validation is complete, publish the application for the desired target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) for your deployment environment. Use `--self-contained true` if the target machine does not have the .NET runtime installed.