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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if the build succeeds.

## 3. Review NuGet Package Versions

Open the `.csproj` file and check that all `<PackageReference>` entries reference current, non-deprecated NuGet packages compatible with your target framework. Use the following command to check for outdated packages:

```bash
dotnet list package --outdated
```

Update any outdated packages as needed.

## 4. Run Existing Tests

If the solution contains test projects, execute the test suite to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any test failures before proceeding.

## 5. Check for Platform-Specific API Usage

Even with a successful build, some APIs may compile but fail at runtime on non-Windows platforms. Search the codebase for usages of:

- `Microsoft.Win32` namespaces
- `System.Windows.Forms` or `System.Drawing` (unless the `EnableWindowsFormsCompatibility` flag is set)
- P/Invoke calls targeting Windows-specific native libraries
- Registry access (`RegistryKey`, etc.)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package to identify and replace these where necessary.

## 6. Run the Application on Target Platforms

Execute the application on each platform you intend to support (Windows, Linux, macOS) to catch any runtime-only issues:

```bash
dotnet run --configuration Release
```

Pay close attention to file path separators, environment variable access, and any OS-specific behavior.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# Framework-dependent deployment
dotnet publish --configuration Release --output ./publish

# Self-contained deployment (example for Linux x64)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish-linux
```

Verify the output in the `./publish` directory contains all expected files and that the application runs correctly from that directory.

## 8. Review Configuration Files

Ensure that any `App.config` or `Web.config` files have been migrated to `appsettings.json` or environment-based configuration where applicable, as `System.Configuration` support is limited in cross-platform .NET.