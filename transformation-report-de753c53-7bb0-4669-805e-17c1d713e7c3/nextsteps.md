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

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not block the build.

## 3. Review NuGet Package Versions

Open the `.csproj` file and inspect all `<PackageReference>` entries. Ensure each package targets a version compatible with your chosen .NET version. You can check for outdated packages using:

```bash
dotnet list package --outdated
```

Update packages where appropriate, then rebuild to confirm no regressions.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any test failures carefully, as they may indicate behavioral differences introduced by the migration rather than build-time issues.

## 5. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been available on .NET Framework but behave differently or are absent on cross-platform .NET. Search the codebase for usages of:

- `System.Web` namespaces
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` members that are no longer supported
- COM interop or P/Invoke calls targeting Windows-only libraries

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to surface any remaining compatibility concerns.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (e.g., Linux, macOS) to catch any runtime issues that would not appear on Windows alone:

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Or for a framework-dependent deployment:

```bash
dotnet publish --configuration Release
```

Review the contents of the `publish` output folder to confirm all required assets and dependencies are present before deploying to the target environment.