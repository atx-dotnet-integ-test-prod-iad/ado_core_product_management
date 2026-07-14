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

Check that all NuGet dependencies referenced in `AdoCore.csproj` are targeting versions compatible with your chosen .NET version. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any outdated packages using:

```bash
dotnet add package <PackageName> --version <LatestVersion>
```

## 4. Check for Removed or Changed APIs

Even without build errors, some APIs behave differently or have been removed in cross-platform .NET compared to .NET Framework. Review the following:

- Any usage of `System.Web` (not available in cross-platform .NET)
- `AppDomain`, `Remoting`, or `BinaryFormatter` usage
- Windows-specific registry or file path assumptions

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.ApiCompat` tool to surface any compatibility concerns.

## 5. Run Existing Tests

If the solution contains test projects, execute them to validate runtime behavior:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET.

## 6. Perform Runtime Smoke Testing

Run the application locally and exercise its primary functionality manually or through integration tests:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Pay particular attention to:

- Database connectivity and ADO.NET operations (given the `AdoCore` naming suggests data access usage)
- Connection string formats, which may differ across environments
- Any platform-specific file path separators (`\` vs `/`)

## 7. Validate Configuration Files

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables, as `System.Configuration.ConfigurationManager` has limited support in cross-platform .NET without the `System.Configuration.ConfigurationManager` NuGet package.

## 8. Test on Target Platform

If the goal is cross-platform support, run the application on each target operating system (Windows, Linux, macOS) to confirm there are no platform-specific runtime failures:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` identifier as needed for your target platforms.