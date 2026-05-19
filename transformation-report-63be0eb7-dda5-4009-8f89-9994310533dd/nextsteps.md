# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-only TFM such as `net472` or `net48`, update it accordingly.

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate deprecated APIs or platform-specific code paths that may fail at runtime.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may compile but fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these issues:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Pay particular attention to:
- `System.Data` and ADO.NET provider usage (relevant given the `AdoCore` project name)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions

## 5. Validate ADO.NET Provider References

Since this project is named `AdoCore`, confirm that any database provider NuGet packages have been updated to their cross-platform compatible versions. For example:

| Legacy Package | Cross-Platform Replacement |
|---|---|
| `System.Data.SqlClient` | `Microsoft.Data.SqlClient` |
| Oracle ODP.NET (legacy) | `Oracle.ManagedDataAccess.Core` |
| MySql.Data (legacy) | `MySql.Data` (latest) or `MySqlConnector` |

Update the `.csproj` references accordingly and re-run `dotnet restore`.

## 6. Test on Target Platform

If the goal is to run on Linux or macOS, execute the build and tests on that operating system directly to catch any remaining runtime issues:

```bash
dotnet run --configuration Release
```

Or publish a self-contained executable for the target platform:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

## 7. Review NuGet Package Versions

Ensure all NuGet dependencies are up to date and compatible with the target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update packages as needed, then rebuild and retest.

## 8. Inspect Output and Configuration Files

- Verify that any `App.config` or `Web.config` files have been migrated to `appsettings.json` where applicable.
- Confirm that connection strings and other configuration values are correctly read using `Microsoft.Extensions.Configuration` if that pattern has been adopted.