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

## 3. Review NuGet Package Versions

Check all `<PackageReference>` entries in `AdoCore.csproj` to confirm that the referenced packages have stable, non-prerelease versions compatible with your target framework. You can audit this with:

```bash
dotnet list package --outdated
```

Update any outdated packages as appropriate.

## 4. Run Existing Tests

If the solution contains test projects, execute the test suite to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate runtime behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Even without build errors, some APIs that compiled successfully may not behave correctly on non-Windows platforms. Review the code for usage of the following, which are common problem areas in migrations:

- `System.Drawing` (use a cross-platform alternative such as `SkiaSharp` if needed)
- Windows Registry access (`Microsoft.Win32.Registry`)
- `System.Web` namespaces
- COM interop or P/Invoke calls targeting Windows-only libraries

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify these at the API level.

## 6. Validate Configuration and App Settings

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables as appropriate for the new hosting model. Verify that `ConfigurationManager` usage has been replaced with `Microsoft.Extensions.Configuration` where applicable.

## 7. Test on Target Operating Systems

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to catch any platform-specific runtime issues that static analysis would not surface.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment environment. Review the output in the `publish` folder before deploying to the target environment.