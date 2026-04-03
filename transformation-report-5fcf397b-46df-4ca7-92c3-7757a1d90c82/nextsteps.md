# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

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

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not block the build.

## 3. Review Removed or Replaced APIs

Check the codebase for any usage of APIs that were available in .NET Framework but have changed behavior in cross-platform .NET. Common areas to review include:

- `System.Configuration` (replaced by `Microsoft.Extensions.Configuration`)
- `System.Web` (not available in cross-platform .NET)
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` members that are no longer supported
- Any P/Invoke calls that may be platform-specific

## 4. Run Existing Tests

If the solution contains a test project, execute the tests to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET rather than outright bugs.

## 5. Validate Runtime Behavior

Run the application and exercise its primary workflows manually or through integration tests. Pay particular attention to:

- File path handling (use `Path.Combine` and avoid hardcoded backslashes)
- Culture and encoding behavior, which can differ across platforms
- Any features that depend on Windows-specific subsystems

## 6. Check NuGet Package Compatibility

Review all NuGet dependencies and confirm they support the target framework. You can use the following command to identify outdated or incompatible packages:

```bash
dotnet list package --outdated
```

Replace any packages that do not support the target framework with their modern equivalents.

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

If you require a self-contained deployment (no .NET runtime required on the target machine), use:

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier for your target platform (e.g., `linux-x64`, `osx-x64`).

## 8. Verify Output on Target Environment

Deploy the contents of the `./publish` folder to the target environment and confirm the application starts and operates correctly. Check application logs for any runtime exceptions that did not surface during local testing.