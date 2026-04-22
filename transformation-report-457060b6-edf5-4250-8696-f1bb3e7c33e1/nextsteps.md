# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
  </PropertyGroup>
</Project>
```

## 2. Restore and Build

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate deprecated APIs or compatibility issues that were silently ignored during transformation.

## 3. Review NuGet Package Versions

Check all NuGet dependencies in `AdoCore.csproj` to confirm they are targeting compatible .NET versions. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework.

## 4. Run Existing Tests

If a test project exists in the solution, execute the test suite to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework APIs and their cross-platform .NET equivalents.

## 5. Check for Platform-Specific API Usage

Review the codebase for any APIs that were available in .NET Framework but have limited or no support in cross-platform .NET. Common areas to inspect include:

- `System.Web` references
- Windows Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) server-side components
- `AppDomain` usage
- `BinaryFormatter` (deprecated and disabled by default in modern .NET)

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to assist with this review:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze .
```

## 6. Test on Target Platforms

Since the goal is cross-platform support, run and validate the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear at build time.

```bash
dotnet run --configuration Release
```

## 7. Validate Output Artifacts

Publish the project and inspect the output to confirm all required files, dependencies, and runtime assets are present:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the `./publish` directory to ensure no legacy `.config` files or platform-specific binaries are unexpectedly included or missing.

## 8. Review Removed Configuration Files

Legacy projects often rely on `app.config` or `web.config`. In cross-platform .NET, configuration is typically handled via `appsettings.json` and `Microsoft.Extensions.Configuration`. Confirm that all configuration values have been correctly migrated and are being loaded at runtime.