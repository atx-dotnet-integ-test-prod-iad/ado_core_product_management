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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Review NuGet Package Versions

Check that all NuGet dependencies referenced in `AdoCore.csproj` are compatible with the target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions available, particularly those that were previously targeting .NET Framework.

## 4. Run Existing Tests

If a test project exists in the solution, execute the test suite to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and modern .NET.

## 5. Check for Removed or Changed APIs

Even without build errors, some APIs behave differently or have been removed in modern .NET. Review the [.NET Upgrade Assistant compatibility analyzer results](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or use the API compatibility analyzer:

```bash
dotnet add package Microsoft.DotNet.ApiCompat
```

Pay particular attention to:
- `System.Data` and ADO.NET-related APIs if `AdoCore` implies database access
- `System.Configuration` (replaced by `Microsoft.Extensions.Configuration`)
- Any platform-specific APIs (e.g., Windows registry, COM interop)

## 6. Test on Target Platform

If cross-platform support is a goal, run and validate the application on each intended operating system (Windows, Linux, macOS) to catch any platform-specific runtime issues that would not appear at compile time.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier:

```bash
# Framework-dependent
dotnet publish --configuration Release --output ./publish

# Self-contained (example for Linux x64)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files and dependencies are present before deploying to the target environment.