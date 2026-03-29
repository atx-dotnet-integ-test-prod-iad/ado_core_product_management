# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

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

Check all NuGet dependencies in `AdoCore.csproj` to confirm they are targeting compatible .NET versions. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any outdated packages using:

```bash
dotnet add package <PackageName> --version <LatestVersion>
```

## 4. Check for Removed or Changed APIs

Review your code for any usage of APIs that were available in .NET Framework but have been removed or altered in cross-platform .NET. The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) can help identify these issues if not already run.

Common areas to check:
- `System.Web` references (not available in cross-platform .NET)
- `AppDomain` usage
- Reflection APIs that have changed behavior
- Windows-specific APIs (e.g., registry access, WinForms, WPF)

## 5. Run Existing Tests

If the solution contains test projects, execute them to validate runtime behavior:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET.

## 6. Validate Runtime Behavior

Run the application locally and exercise the primary workflows to confirm expected behavior:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Pay particular attention to:
- Database connectivity (ADO.NET connection strings and drivers may need updating)
- File path handling (ensure `Path.Combine` is used rather than hardcoded backslashes)
- Configuration loading (if migrated from `App.config` to `appsettings.json`)

## 7. Test on Target Platforms

Since the goal is cross-platform compatibility, run and validate the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific issues.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier for your target environment (`win-x64`, `osx-x64`, etc.).