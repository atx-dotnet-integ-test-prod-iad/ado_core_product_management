# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if the build succeeds.

## 3. Review NuGet Package Versions

Open the `.csproj` file and check that all `<PackageReference>` entries reference versions compatible with your target framework. Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions available, particularly those that previously targeted .NET Framework.

## 4. Check for Removed or Changed APIs

Even with a clean build, some APIs behave differently on cross-platform .NET compared to .NET Framework. Pay specific attention to:

- `System.Data` and ADO.NET provider usage (given the `AdoCore` project name, this is likely relevant)
- Any database drivers (e.g., `System.Data.SqlClient` should be replaced with `Microsoft.Data.SqlClient`)
- File path handling — use `Path.Combine` consistently to ensure cross-platform compatibility
- `ConfigurationManager` — this requires the `System.Configuration.ConfigurationManager` NuGet package on cross-platform .NET

## 5. Run Existing Tests

If a test project exists in the solution, execute the tests to validate runtime behavior:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output file for any failed or skipped tests. Address any failures before proceeding.

## 6. Perform Runtime Validation

If no automated tests exist, manually exercise the core data access functionality to confirm:

- Database connections open and close correctly
- Queries return expected results
- Transactions commit and roll back as expected
- Connection strings are being read correctly from configuration

## 7. Validate on Target Operating Systems

Since the goal is cross-platform support, run the application on each intended operating system (e.g., Windows, Linux, macOS):

```bash
dotnet run --configuration Release
```

Confirm there are no platform-specific runtime exceptions, particularly around file I/O, database drivers, or environment-specific configuration.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# Framework-dependent (requires .NET runtime installed on target machine)
dotnet publish --configuration Release --output ./publish

# Self-contained (bundles the runtime)
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Verify the contents of the `./publish` directory before deploying to the target environment.