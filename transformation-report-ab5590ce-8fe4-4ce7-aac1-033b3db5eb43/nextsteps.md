# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Debug
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete APIs, as these may indicate areas of the code that could cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during the migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee correct runtime behavior, so test coverage is critical at this stage.

## 4. Validate Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0`):

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure all projects in the solution are targeting a consistent and supported framework version.

## 5. Check for Removed or Changed APIs

Review the code for any usage of APIs that existed in .NET Framework but have changed or been removed in modern .NET. The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` compatibility shims may be relevant depending on what APIs are in use.

Pay particular attention to:
- `System.Web` usage (not available in modern .NET)
- Windows Communication Foundation (WCF) client/server code
- Windows-specific APIs if cross-platform support is required

## 6. Run the Application

Execute the application directly to confirm it starts and operates correctly:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Perform manual validation of core functionality, particularly any database access, file I/O, or network operations that may behave differently across platforms.

## 7. Publish the Application

Once validation is complete, publish the application for deployment:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be installed on the target machine:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier for your target environment (e.g., `linux-x64`, `osx-x64`).

## 8. Review Published Output

Inspect the contents of the `./publish` directory to confirm all expected assemblies, configuration files, and assets are present before deploying to the target environment.