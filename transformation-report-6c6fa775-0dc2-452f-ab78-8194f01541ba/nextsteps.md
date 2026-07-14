# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`).

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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

## 3. Review NuGet Package Versions

Open the `.csproj` file and check that all `<PackageReference>` entries reference versions compatible with your target framework. Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions available.

## 4. Check for Removed or Changed APIs

Even without build errors, some APIs behave differently or have been removed in cross-platform .NET compared to .NET Framework. Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.ApiCompat` tool to surface any potential runtime compatibility issues.

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze
```

## 5. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --verbosity normal
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET.

## 6. Validate Platform-Specific Behavior

Since the project was migrated to cross-platform .NET, verify that no code paths rely on Windows-specific functionality such as:

- `System.Windows.Forms` or `System.Web` namespaces
- Windows Registry access
- COM interop
- Windows-only file path assumptions (e.g., backslash separators)

Run the application on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement.

## 7. Test Against a Real Data Source

Since the project name suggests ADO.NET usage (`AdoCore`), verify that all database connections, queries, and transactions function correctly at runtime against your actual or a representative data source. Pay particular attention to:

- Connection string formats
- Provider-specific behavior differences (e.g., `System.Data.SqlClient` vs `Microsoft.Data.SqlClient`)
- Any use of `DataSet` or `DataTable` which, while still supported, may behave differently in edge cases

## 8. Review Output Artifacts

After a successful Release build, inspect the output directory (`bin/Release/net8.0/`) to confirm all expected assemblies, configuration files, and dependencies are present.

## 9. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory before deploying to your target environment.