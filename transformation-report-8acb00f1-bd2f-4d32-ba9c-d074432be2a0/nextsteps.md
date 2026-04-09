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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Review NuGet Package Versions

Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework, particularly any that were previously targeting .NET Framework.

## 4. Check for Removed or Changed APIs

Review any usage of APIs that were available in .NET Framework but have been removed or altered in cross-platform .NET. The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.ApiCompat` tool can assist with this.

Pay particular attention to:
- `System.Data` and ADO.NET-related APIs, given the project name `AdoCore`
- Any database provider libraries (e.g., `System.Data.SqlClient` should be replaced with `Microsoft.Data.SqlClient`)

## 5. Run Existing Tests

If a test project exists in the solution, execute the tests to validate runtime behavior:

```bash
dotnet test --configuration Release --logger trx
```

Review the test results for any failures that may indicate behavioral differences between .NET Framework and the new target framework.

## 6. Perform Runtime Validation

Run the application locally and exercise the primary workflows, particularly any database connectivity or data access operations that ADO.NET components handle. Verify:

- Connection strings are correctly configured for the target environment
- Database operations (queries, inserts, updates, deletes) behave as expected
- Exception handling paths function correctly

## 7. Review Configuration Files

Ensure that any configuration previously held in `App.config` or `Web.config` has been properly migrated to `appsettings.json` or environment variables, as .NET no longer relies on XML-based configuration by default.

## 8. Validate Platform-Specific Behavior

Since this is now a cross-platform project, test on each operating system you intend to support (Windows, Linux, macOS) to surface any platform-specific issues such as:

- File path separator differences
- Case sensitivity in file system operations
- Platform-specific native library dependencies

## 9. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required assemblies and configuration files are present before deploying to the target environment.