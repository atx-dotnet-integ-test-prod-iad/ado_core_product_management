# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

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

Review the output for any warnings about deprecated packages or packages that do not support the target framework. If any packages are flagged, check NuGet.org for updated versions and replace them in the `.csproj` file.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review the build output for any warnings, particularly around nullable reference types, obsolete API usage, or platform compatibility analyzers (e.g., `CA1416`).

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Run the .NET Upgrade Assistant compatibility analyzer or use the built-in platform compatibility warnings to identify any APIs that may not behave identically on Linux or macOS if cross-platform support is required:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to APIs in the following categories:
- `System.Data` (ADO.NET behavior differences with specific providers)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific security or identity APIs

## 6. Validate ADO.NET Functionality

Since the project name suggests ADO.NET usage (`AdoCore`), verify that the database provider packages are current and compatible. For example:

- **SQL Server**: Ensure `Microsoft.Data.SqlClient` is used instead of the legacy `System.Data.SqlClient`.
- **Other providers**: Confirm the provider NuGet package explicitly targets `netstandard2.0` or `net6.0`/`net8.0`.

Test all database connection, query, and transaction logic against a real or local database instance to confirm correct behavior.

## 7. Review Configuration and Connection Strings

Legacy projects often rely on `App.config` or `Web.config`. Cross-platform .NET uses `appsettings.json` by default. Confirm that connection strings and application settings have been migrated appropriately and that the application reads them correctly at runtime.

## 8. Run the Application

Execute the application directly to perform an end-to-end runtime validation:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Verify the application starts without runtime exceptions and behaves as expected.

## 9. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent release build:

**Framework-dependent:**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Verify the output in the `./publish` directory contains all expected files before deploying to the target environment.