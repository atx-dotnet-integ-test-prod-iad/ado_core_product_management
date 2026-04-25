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

## 3. Review NuGet Package Versions

Check that all NuGet dependencies referenced in `AdoCore.csproj` are compatible with the target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework.

## 4. Check for Removed or Changed APIs

Review the code for any usage of APIs that were available in .NET Framework but have changed or been removed in cross-platform .NET. Microsoft provides a compatibility analyzer that can help:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Address any diagnostics raised by the analyzer.

## 5. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output for any failed or skipped tests and investigate the root causes.

## 6. Manual Functional Testing

If there are no automated tests, perform manual testing of the core functionality of `AdoCore`, particularly around:

- Database connections and ADO.NET operations, as connection string formats and provider registrations can differ between .NET Framework and cross-platform .NET.
- Any platform-specific code paths (e.g., Windows registry access, COM interop) that may not function on non-Windows platforms.

## 7. Validate Platform-Specific Behavior

If the project uses any of the following, verify they behave correctly on the target platform:

- `System.Data` providers (e.g., SQL Server, OLE DB — note that OLE DB is Windows-only)
- File path handling (use `Path.Combine` and avoid hardcoded backslashes)
- Encoding and culture-sensitive operations

## 8. Publish the Application

Once testing is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required files and dependencies are present before deploying to the target environment.