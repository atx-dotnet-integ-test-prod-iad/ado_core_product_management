# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate and test the migrated project before deploying it.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`). Example:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or incompatible packages and update them as needed using:

```bash
dotnet list package --outdated
dotnet add package <PackageName>
```

## 3. Build the Solution

Perform a full build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, as some may indicate runtime issues even if the build succeeds.

## 4. Run the Test Suite

If the solution contains a test project, execute all tests to verify functional correctness:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

If no tests exist, consider writing unit tests for the core functionality in `AdoCore` to validate that data access behavior is consistent with the original legacy project.

## 5. Validate ADO.NET Functionality

Since the project is named `AdoCore`, it likely involves ADO.NET data access. Verify the following:

- Connection strings are correctly configured for the target environment (e.g., in `appsettings.json` or environment variables rather than `app.config` or `web.config`).
- Any `System.Data` or database provider references (e.g., `Microsoft.Data.SqlClient`) are using the cross-platform compatible versions.
- Confirm that `System.Data.SqlClient` has been replaced with `Microsoft.Data.SqlClient` if applicable, as the former has limited support in cross-platform .NET.

## 6. Check for Platform-Specific API Usage

Run the .NET Compatibility Analyzer to detect any remaining platform-specific API calls:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Review and resolve any `CA1416` (platform compatibility) warnings.

## 7. Test on Target Platform

If the goal is cross-platform support, run and test the application explicitly on each intended platform (Windows, Linux, macOS):

```bash
dotnet run --configuration Release
```

Confirm that behavior is consistent across platforms, particularly around file paths, line endings, and database connectivity.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required assemblies and configuration files are present before deploying to the target environment.