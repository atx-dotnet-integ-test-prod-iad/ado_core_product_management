# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

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

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Removed or Changed APIs

Even without build errors, some APIs behave differently or have been removed in cross-platform .NET compared to .NET Framework. Pay particular attention to:

- **`System.Data`** and ADO.NET usage, since `AdoCore` suggests database interaction. Verify that your database provider NuGet packages (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, etc.) are updated to versions compatible with your target framework.
- Any use of `System.Configuration.ConfigurationManager` — this requires the `System.Configuration.ConfigurationManager` NuGet package on cross-platform .NET.
- Any Windows-specific APIs (registry access, WCF, Windows Authentication) that may compile but fail at runtime on non-Windows platforms.

## 5. Validate NuGet Package Compatibility

Check that all NuGet dependencies are compatible with your target framework:

```bash
dotnet list package --outdated
```

Update any outdated packages, particularly those that previously targeted `.NET Framework` only.

## 6. Run the Application and Perform Smoke Testing

Execute the application and perform basic functional testing against your expected workflows:

```bash
dotnet run --project AdoCore --configuration Release
```

Test all major data access paths, as ADO.NET connection handling and transaction behavior can differ slightly between .NET Framework and cross-platform .NET.

## 7. Review Runtime Configuration

Ensure that your `appsettings.json` or equivalent configuration files contain the correct connection strings and settings, as `App.config` / `Web.config` transforms may not carry over automatically.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required files and dependencies are present before deploying to your target environment.