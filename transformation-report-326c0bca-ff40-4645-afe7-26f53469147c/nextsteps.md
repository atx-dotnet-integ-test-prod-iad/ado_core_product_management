# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy the migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net6.0`, `net7.0`, or `net8.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If multiple target frameworks are needed, use `<TargetFrameworks>` (plural) with a semicolon-separated list.

## 2. Restore NuGet Packages

Run the following command from the solution root to ensure all dependencies are properly restored:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages that may need to be updated.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings introduced by the migration:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete APIs, as these may indicate compatibility concerns.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after the migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully. Failures may indicate platform-specific behavior differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Windows-Specific API Usage

Even without build errors, the code may reference APIs that are Windows-only (e.g., registry access, `System.Windows.Forms`, COM interop). Use the .NET Compatibility Analyzer or review the runtime behavior on a non-Windows platform if cross-platform execution is a requirement.

You can add the analyzer via:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

## 6. Validate Runtime Behavior

Run the application and exercise its primary functionality manually or through integration tests. Pay particular attention to:

- File path handling (use `Path.Combine` and avoid hardcoded backslashes)
- Configuration file loading (e.g., migration from `app.config` to `appsettings.json`)
- Any database or ADO.NET connection strings that may have changed format or provider requirements

## 7. Review ADO.NET Provider References

Given the project name `AdoCore`, confirm that the ADO.NET provider packages being used are compatible with the target .NET version. For example, if SQL Server is used:

```bash
dotnet add package Microsoft.Data.SqlClient
```

Replace any references to `System.Data.SqlClient` with `Microsoft.Data.SqlClient`, as the latter is the actively maintained cross-platform version.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required files are present, and verify the application runs correctly from the published output.