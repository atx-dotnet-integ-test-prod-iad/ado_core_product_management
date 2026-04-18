# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
  </PropertyGroup>
</Project>
```

## 2. Restore and Build

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Review NuGet Package Versions

Check that all NuGet dependencies referenced in `AdoCore.csproj` are compatible with your target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions available, particularly those that were previously targeting .NET Framework.

## 4. Check for Removed or Changed APIs

Even without build errors, some APIs behave differently or have been removed in cross-platform .NET. Review the following areas manually:

- Any usage of `System.Web` (not available in .NET Core/.NET 5+)
- `AppDomain`, `Remoting`, or `Reflection.Emit` usage
- Windows-specific APIs (registry access, COM interop, etc.)
- Any configuration that previously relied on `app.config` or `web.config`

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) if needed.

## 5. Run Existing Tests

If a test project exists in the solution, execute the tests to verify runtime behavior:

```bash
dotnet test --configuration Release --logger trx
```

Review the output for any test failures that may indicate behavioral differences between .NET Framework and the new target framework.

## 6. Perform Runtime Validation

Run the application locally and exercise the core functionality of `AdoCore`. Pay particular attention to:

- Database connectivity and ADO.NET operations, as connection string formats or provider registrations may differ
- Any file I/O paths that previously used Windows-style absolute paths
- Exception handling behavior that may differ across platforms

## 7. Validate Cross-Platform Behavior (If Applicable)

If the intent is to run on Linux or macOS, test the application on those platforms explicitly:

```bash
dotnet run --configuration Release
```

Check for any `PlatformNotSupportedException` at runtime, which would not have been caught at compile time.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assets and dependencies are present before deploying to the target environment.