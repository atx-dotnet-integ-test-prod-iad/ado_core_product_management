# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Review NuGet Package Versions

Check that all NuGet dependencies referenced in `AdoCore.csproj` are compatible with the target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework.

## 4. Check for Removed or Changed APIs

Review the code for any usage of APIs that were available in .NET Framework but have changed or been removed in modern .NET. The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` compatibility shims may help identify these at runtime.

Common areas to check:
- `System.Web` usages (not available in modern .NET)
- `AppDomain` APIs with limited support
- Remoting or binary serialization APIs
- Windows-specific registry or COM interop calls

## 5. Run Existing Tests

If the solution contains a test project, execute the test suite to verify functional correctness:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether failures are due to migration-related behavioral changes.

## 6. Validate Runtime Behavior

Run the application locally and exercise the primary workflows to confirm runtime behavior matches expectations from the original .NET Framework version. Pay particular attention to:

- File I/O path handling (path separators differ on Linux/macOS)
- Configuration file loading (`app.config` vs `appsettings.json`)
- Database connectivity if ADO.NET is in use (verify connection strings and driver compatibility)

## 7. Cross-Platform Smoke Test

If cross-platform support is a goal, run the application on each target operating system (Windows, Linux, macOS) to identify any platform-specific issues:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# Framework-dependent deployment
dotnet publish --configuration Release --output ./publish

# Self-contained deployment for a specific platform
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files are present before deploying to the target environment.