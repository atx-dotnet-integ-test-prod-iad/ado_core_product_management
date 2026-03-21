# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to the intended cross-platform .NET version (e.g., `net6.0`, `net7.0`, or `net8.0`):

```xml
<TargetFramework>net8.0</TargetFramework>
```

If multiple targets are required, ensure `<TargetFrameworks>` (plural) is used with the appropriate TFMs.

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Verify that no warnings are being treated as errors and that all output assemblies are produced in the expected `bin/Release` directories.

## 3. Run Existing Tests

If the solution contains test projects, execute them to confirm existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Runtime Compatibility Issues

Even with a clean build, certain APIs behave differently or are unavailable on cross-platform .NET. Review the code for usage of:

- `System.Web` namespaces (not available outside of ASP.NET Core)
- Windows-only APIs such as the registry (`Microsoft.Win32.Registry`), WMI, or COM interop
- `AppDomain.CreateDomain` (no longer supported)
- Binary serialization via `BinaryFormatter` (disabled by default in .NET 5+)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.ApiCompat` tool to surface any remaining compatibility concerns.

## 5. Review NuGet Package Versions

Confirm that all NuGet dependencies reference versions that support your target framework. Open the `.csproj` file and cross-check each `<PackageReference>` against the package's supported frameworks on [nuget.org](https://www.nuget.org).

```bash
dotnet list package --outdated
```

Update packages where necessary:

```bash
dotnet add package <PackageName> --version <LatestVersion>
```

## 6. Test on Target Operating Systems

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a build.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application for the target environment.

**Framework-dependent publish:**

```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained publish (includes the .NET runtime):**

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (RID) for your target platform (e.g., `win-x64`, `osx-x64`, `osx-arm64`).

## 8. Verify Published Output

Navigate to the publish output directory and confirm all expected files are present, then execute the application directly from that directory to ensure the published output runs correctly in isolation from the development environment.