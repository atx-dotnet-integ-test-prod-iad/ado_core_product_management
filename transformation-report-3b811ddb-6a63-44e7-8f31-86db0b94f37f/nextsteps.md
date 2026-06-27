# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

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

Ensure there are no warnings that could indicate compatibility issues, such as deprecated APIs or platform-specific calls.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may have changed behavior or may not be supported on non-Windows platforms. Use the .NET Upgrade Assistant compatibility analyzer or review the [.NET API compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) for any APIs used in the project.

Pay particular attention to:
- `System.Data` and ADO.NET provider usage (given the `AdoCore` project name)
- Database driver NuGet packages (e.g., ensure you are using cross-platform compatible versions of drivers such as `Microsoft.Data.SqlClient` instead of `System.Data.SqlClient`)
- Any use of `ConfigurationManager` — replace with `Microsoft.Extensions.Configuration` if needed

## 5. Validate Database Connectivity

Since this project appears to be ADO.NET related, verify that:
- Connection strings are correctly configured for the new environment
- The database provider NuGet package is explicitly referenced and up to date
- Any `app.config` connection string sections have been migrated to `appsettings.json` if applicable

## 6. Review NuGet Package Versions

Check that all NuGet dependencies are compatible with the target framework:

```bash
dotnet list package --outdated
```

Update any outdated packages, particularly database drivers and serialization libraries.

## 7. Run on Target Platform

If cross-platform support (Linux/macOS) is a goal, run the application on the intended non-Windows platform to surface any remaining runtime issues:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier:

```bash
# Framework-dependent (requires .NET runtime on target machine)
dotnet publish --configuration Release --output ./publish

# Self-contained (includes runtime)
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Verify the output in the `./publish` directory before deploying to the target environment.