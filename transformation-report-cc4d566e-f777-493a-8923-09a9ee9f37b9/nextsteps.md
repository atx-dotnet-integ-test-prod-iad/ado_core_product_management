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

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they are not hard errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any test failures before proceeding further.

## 4. Validate Runtime Behavior

Run the application and exercise its core functionality manually or through integration tests. Pay particular attention to:

- Database connectivity and ADO.NET operations, since `AdoCore` suggests data access logic is central to this project.
- Any areas that previously relied on Windows-specific APIs (e.g., `System.Data.OleDb`, MSDTC, or Windows Authentication) that may behave differently or require additional NuGet packages on non-Windows platforms.

## 5. Check for Platform-Specific Dependencies

Review all NuGet package references in `AdoCore.csproj` for packages that may only support Windows. You can inspect this with:

```bash
dotnet list package
```

If any packages are Windows-only, evaluate whether cross-platform alternatives exist or add a `<RuntimeIdentifier>` or OS condition to the project file if Windows-only deployment is acceptable.

## 6. Review `App.config` or `appsettings.json`

Legacy projects often use `App.config` for connection strings and settings. Confirm that configuration has been migrated to `appsettings.json` or environment variables, which are the standard approach in modern .NET:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "your-connection-string-here"
  }
}
```

Update any code that uses `ConfigurationManager` to use `Microsoft.Extensions.Configuration` if applicable.

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files are present before deploying to the target environment.