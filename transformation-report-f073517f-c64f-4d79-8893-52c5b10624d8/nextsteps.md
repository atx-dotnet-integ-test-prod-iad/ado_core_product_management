# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework is set to the intended cross-platform .NET version (e.g., `net6.0`, `net7.0`, or `net8.0`):

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

Ensure there are no warnings that could indicate compatibility issues carried over from the legacy project.

## 3. Review Removed or Replaced APIs

Check for any use of APIs that were available in .NET Framework but have changed behavior in cross-platform .NET. Common areas to review include:

- `System.Configuration` (replaced by `Microsoft.Extensions.Configuration`)
- `System.Web` (not available in cross-platform .NET)
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage
- Any P/Invoke calls targeting Windows-specific native libraries

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET rather than simple compilation issues.

## 5. Validate NuGet Package Compatibility

Check that all NuGet dependencies referenced in `AdoCore.csproj` support the target framework. You can inspect compatibility using the NuGet Package Manager in Visual Studio or by reviewing each package on [nuget.org](https://www.nuget.org). Replace any packages that only target `.NET Framework` with their cross-platform equivalents.

## 6. Test on a Non-Windows Platform (if applicable)

If cross-platform support is a goal, run the application on Linux or macOS to surface any platform-specific issues:

```bash
dotnet run --configuration Release
```

Pay attention to:
- File path separator differences (`\` vs `/`)
- Case-sensitive file systems on Linux
- Platform-specific runtime behaviors

## 7. Review Output and Runtime Behavior

Execute the application and compare its output and behavior against the original .NET Framework version. Focus on:

- Database connectivity (given the `AdoCore` naming suggests ADO.NET usage)
- Connection string configurations
- Data type mappings and query results
- Exception handling paths

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assemblies and configuration files are present before deploying to the target environment.