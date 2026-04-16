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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if the build succeeds.

## 3. Review NuGet Package Versions

Open the `.csproj` file and check all `<PackageReference>` entries. Ensure that:
- No packages are targeting `net45`, `net472`, or other legacy frameworks exclusively.
- Packages have stable, non-prerelease versions unless intentionally using a preview.

You can check for outdated packages with:

```bash
dotnet list package --outdated
```

Update packages as appropriate using:

```bash
dotnet add package <PackageName> --version <LatestStableVersion>
```

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any test failures carefully, as they may indicate behavioral differences introduced by the framework migration rather than pre-existing bugs.

## 5. Check for Platform-Specific Code

Search the codebase for any APIs that were Windows-specific in the original .NET Framework project. Common areas to review include:

- `System.Web` usage (not available in cross-platform .NET)
- `Microsoft.Win32` registry access
- Windows Communication Foundation (WCF) server-side code
- `AppDomain` usage with unsupported members

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package where needed.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (e.g., Linux, macOS) to catch any remaining platform-specific runtime issues:

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

**Framework-dependent (requires .NET runtime on target machine):**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (bundles the runtime):**
```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier for your environment (e.g., `win-x64`, `osx-x64`).

## 8. Validate the Published Output

Navigate to the `./publish` directory and run the output directly to confirm the published artifact behaves as expected before deploying to the target environment.

```bash
cd ./publish
dotnet AdoCore.dll
```

Or, if published as a self-contained executable:

```bash
./AdoCore
```