# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

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

Ensure there are no warnings that could indicate compatibility issues, such as deprecated APIs or platform-specific code paths.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may have changed behavior on non-Windows platforms. Review the code for usage of the following, which are common sources of cross-platform issues:

- `System.Drawing` (requires `System.Drawing.Common` and may not be fully supported on Linux/macOS)
- Windows Registry access (`Microsoft.Win32.Registry`)
- COM interop or P/Invoke calls targeting Windows-specific libraries
- `AppDomain` usage that relied on legacy behavior
- File path separators (use `Path.Combine` and `Path.DirectorySeparatorChar`)

## 5. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` are compatible with the target framework. You can inspect this with:

```bash
dotnet list package --outdated
dotnet list package --deprecated
```

Update any packages that have newer versions with cross-platform support.

## 6. Validate Configuration Files

If the project previously relied on `app.config` or `web.config`, confirm that configuration has been migrated to `appsettings.json` or environment variables where applicable, as `System.Configuration` support is limited in cross-platform .NET.

## 7. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that would not appear during a Windows-only build.

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
# Framework-dependent deployment
dotnet publish --configuration Release --output ./publish

# Self-contained deployment for a specific platform
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all expected files are present before deploying to the target environment.