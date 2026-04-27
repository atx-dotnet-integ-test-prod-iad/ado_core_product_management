# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any test failures before proceeding further.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been available in .NET Framework but behave differently or are unsupported on non-Windows platforms in cross-platform .NET. Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for such usage:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to:
- `System.Data` and ADO.NET provider usage (relevant given the `AdoCore` project name)
- Any database drivers or connection string configurations that may be platform-dependent
- `System.Configuration.ConfigurationManager` (requires the `System.Configuration.ConfigurationManager` NuGet package in cross-platform .NET)

## 5. Validate NuGet Package Compatibility

Inspect `AdoCore.csproj` and any other project files to ensure all referenced NuGet packages have versions that support your target framework. You can check this with:

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

Update any outdated or vulnerable packages as appropriate.

## 6. Test Database Connectivity

Since this project appears to be ADO.NET focused, validate that all database connections, queries, and transactions function correctly against your target database in the new runtime environment. Run integration tests or a manual smoke test covering:

- Opening and closing connections
- Executing queries and stored procedures
- Transaction commit and rollback behavior
- Correct handling of connection strings from configuration

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assemblies and configuration files are present before deploying to your target environment.