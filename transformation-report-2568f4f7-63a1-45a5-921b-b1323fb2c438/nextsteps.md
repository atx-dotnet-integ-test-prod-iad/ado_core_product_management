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

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that may have been resolved from legacy sources. Replace any packages that target only `net4x` or `netstandard1.x` with their modern equivalents where applicable.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Address any warnings that surface during the build, particularly those related to nullable reference types, obsolete APIs, or platform compatibility.

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review test output carefully. Failures may indicate behavioral differences between the legacy .NET Framework runtime and the current .NET runtime, such as changes in:

- `System.Data` behavior
- ADO.NET provider registration
- Connection string handling
- Exception types thrown by database operations

## 5. Validate ADO.NET Provider Registration

Since the project is named `AdoCore`, it likely involves ADO.NET data access. In .NET (Core and later), database providers are no longer registered automatically via `machine.config`. Verify that any required providers are explicitly registered in code or via the appropriate NuGet package.

For example, if using SQL Server:

```csharp
// Ensure the Microsoft.Data.SqlClient package is referenced
// and used in place of System.Data.SqlClient where applicable
```

Check that connection strings are being read correctly from configuration, as `ConfigurationManager` behavior may differ. Use `Microsoft.Extensions.Configuration` if the project has been updated to use the modern configuration system.

## 6. Check for Platform-Specific API Usage

Run the .NET Compatibility Analyzer to detect any remaining platform-specific API calls:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay attention to any `CA1416` (platform compatibility) warnings, which indicate APIs that may not function on non-Windows platforms.

## 7. Smoke Test Core Functionality

Manually exercise the primary data access paths of the application against a real or test database instance to confirm:

- Connections open and close correctly
- Queries return expected results
- Transactions commit and roll back as expected
- Exceptions are handled and surfaced correctly

## 8. Review Output Artifacts

Confirm the build output is placed in the expected directory:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` folder to ensure all required assemblies, configuration files, and dependencies are present before proceeding with any deployment activity.