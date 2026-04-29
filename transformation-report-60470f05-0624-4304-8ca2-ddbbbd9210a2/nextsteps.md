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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Check for Removed or Changed APIs

Even without build errors, some APIs behave differently in cross-platform .NET compared to .NET Framework. Review the code for usage of the following common problem areas:

- `System.Data` and ADO.NET provider-specific types (given the `AdoCore` naming, this is especially relevant)
- `ConfigurationManager` — replaced by `Microsoft.Extensions.Configuration`
- `AppDomain`, `Thread.Abort`, or Remoting APIs
- Windows-only APIs such as the registry or certain `System.Drawing` types

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package to surface any platform-specific API usage.

## 4. Review NuGet Package Versions

Open the `.csproj` file and verify all NuGet packages reference versions compatible with your target framework. Run:

```bash
dotnet list package --outdated
```

Update any outdated packages, paying particular attention to database drivers or ADO.NET providers (e.g., `System.Data.SqlClient` should be replaced with `Microsoft.Data.SqlClient` for modern .NET).

## 5. Run Existing Tests

If the solution contains a test project, execute the test suite to confirm runtime behavior is correct:

```bash
dotnet test --configuration Release --logger trx
```

Review the output for any failed or skipped tests. Failed tests may indicate behavioral differences between .NET Framework and cross-platform .NET that did not surface as build errors.

## 6. Perform Runtime Validation

Run the application and exercise its core data access paths. Specifically for an ADO.NET-focused library:

- Test all connection open/close operations
- Validate query execution and result set reading
- Confirm transaction handling behaves as expected
- Test against all target database platforms if cross-database support is a goal

## 7. Check Configuration Loading

If the project previously relied on `App.config` or `Web.config`, confirm that configuration is now loaded correctly using the .NET configuration system. Connection strings and provider settings may need to be moved to `appsettings.json` or provided via environment variables.

## 8. Publish the Application

Once validation is complete, publish the project using:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the output directory contains all required assemblies and that the application runs correctly from the published output on the target operating system.