# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). For example:

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

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Removed or Changed APIs

Cross-platform .NET removed several APIs that existed in .NET Framework. Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any runtime-level compatibility concerns that do not surface as build errors:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to:
- `System.Web` dependencies (not available in .NET Core/.NET 5+)
- Windows-only APIs such as the registry, WMI, or certain cryptography providers
- `AppDomain` usage
- Remoting or binary serialization

## 5. Validate NuGet Package Compatibility

Review all NuGet package references in `AdoCore.csproj` and confirm each package supports your target framework. You can inspect this on [nuget.org](https://www.nuget.org) or by reviewing the `lib` folders inside the `.nupkg` files in your local cache.

## 6. Perform Runtime Smoke Testing

Run the application and exercise its primary code paths manually or through integration tests. Build errors alone do not guarantee runtime correctness, especially after a framework migration.

```bash
dotnet run --configuration Release
```

## 7. Review Configuration Files

.NET Framework used `App.config` or `Web.config`. Cross-platform .NET uses `appsettings.json` and the `Microsoft.Extensions.Configuration` stack. Confirm that all configuration values have been migrated correctly and are being read at runtime.

## 8. Publish the Application

Once validation is complete, publish the application for your target environment:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment (no .NET runtime required on the target machine):

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment target.