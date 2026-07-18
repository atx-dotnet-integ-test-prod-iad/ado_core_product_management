# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this is consistent with any dependent or consuming projects in the solution.

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

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not cause build failures.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate runtime behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Runtime Compatibility Issues

Even with a clean build, certain APIs behave differently or are unsupported on cross-platform .NET. Pay attention to the following areas:

- **Windows-specific APIs**: Features such as the registry, WCF server-side hosting, `System.Drawing` (GDI+), and certain `System.Security` APIs may not function on Linux or macOS without additional packages or replacements.
- **App.config / Web.config**: Configuration has moved to `appsettings.json` and `Microsoft.Extensions.Configuration`. Verify that any configuration loading still works as expected.
- **Reflection and serialization**: Some reflection-based patterns behave differently under .NET's trimming and AOT considerations.

## 5. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` have versions compatible with the target framework. Use the following command to identify outdated packages:

```bash
dotnet list package --outdated
```

Replace any packages that target only `net45` or similar legacy monikers with their modern equivalents where available.

## 6. Validate ADO-Specific Functionality

Given the project name `AdoCore`, it likely involves ADO.NET data access. Verify the following:

- Connection strings are correctly configured for the target environment.
- Any use of `System.Data.OleDb` or `System.Data.Odbc` is reviewed, as these have platform limitations on non-Windows systems.
- If SQL Server is the target database, confirm that `Microsoft.Data.SqlClient` is used rather than the older `System.Data.SqlClient`, as the former is the actively maintained cross-platform package.

```xml
<PackageReference Include="Microsoft.Data.SqlClient" Version="5.x.x" />
```

## 7. Perform Integration Testing

Execute integration tests or manual smoke tests against a real or representative data source to confirm that data access operations (queries, transactions, connection pooling) behave correctly under the new runtime.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# Framework-dependent deployment
dotnet publish --configuration Release --output ./publish

# Self-contained deployment for a specific platform
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` folder to confirm all required files and dependencies are present before deploying to the target environment.