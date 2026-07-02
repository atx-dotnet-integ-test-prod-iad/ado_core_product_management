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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Removed or Changed APIs

Even without build errors, some APIs behave differently across .NET versions. Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` compatibility tooling to scan for runtime-breaking changes.

## 5. Review NuGet Package Versions

Open the `.csproj` file and verify that all NuGet package references are targeting versions compatible with your chosen .NET target framework. Run:

```bash
dotnet list package --outdated
```

Update any outdated packages that have stable releases compatible with your target framework.

## 6. Validate Platform-Specific Behavior

Since this is a cross-platform migration, test the application on each target operating system (Windows, Linux, macOS) if applicable. Pay particular attention to:

- File path separators
- Registry access calls (not available on Linux/macOS)
- Windows-specific APIs such as those in `System.Drawing` or `Microsoft.Win32`

## 7. Review Configuration and App Settings

If the project previously used `App.config` or `Web.config`, confirm that configuration has been migrated to `appsettings.json` or environment variables, as `System.Configuration` support is limited in cross-platform .NET.

## 8. Perform a Runtime Smoke Test

Run the application directly and exercise its primary code paths:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Confirm that the application starts, connects to any required data sources, and produces expected output.

## 9. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) as needed. Review the publish output directory to confirm all required files are present.