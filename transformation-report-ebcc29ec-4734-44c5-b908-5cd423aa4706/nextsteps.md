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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if they do not produce build errors.

## 3. Review NuGet Package Versions

Open each `.csproj` file and check that all `<PackageReference>` entries reference versions compatible with your target framework. Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions available, particularly those that were carried over from the legacy project.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework APIs and the cross-platform .NET equivalents.

## 5. Check for Platform-Specific API Usage

Search the codebase for APIs that were available in .NET Framework but have limited or no support in cross-platform .NET. Common areas to check include:

- `System.Web` references
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage
- `BinaryFormatter` (deprecated and disabled by default)
- COM interop or P/Invoke calls targeting Windows-specific libraries

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining compatibility concerns.

## 6. Test on All Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime failures that would not appear during a Windows-only build.

```bash
dotnet run --configuration Release
```

## 7. Review Configuration and App Settings

Ensure that any configuration previously handled by `App.config` or `Web.config` has been properly migrated to `appsettings.json` or environment variables, and that the application reads these values correctly at runtime using `Microsoft.Extensions.Configuration`.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) as needed. Review the contents of the publish output directory to confirm all required assets are present before deploying.