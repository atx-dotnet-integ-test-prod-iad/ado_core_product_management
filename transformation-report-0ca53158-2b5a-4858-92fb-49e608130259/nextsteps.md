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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Even without build errors, certain APIs that compiled successfully may not behave correctly or may throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Review usage of the following areas:

- `System.Drawing` (GDI+) — consider replacing with a cross-platform library such as `SkiaSharp` or `ImageSharp`
- `Microsoft.Win32` registry APIs
- Windows Communication Foundation (WCF) client/server code
- `AppDomain` and remoting APIs
- COM interop

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining platform-specific calls.

## 5. Validate NuGet Package Compatibility

Confirm that all NuGet packages referenced in `AdoCore.csproj` support the target framework. Open the `.csproj` file and cross-check each `<PackageReference>` against the package's supported frameworks on [nuget.org](https://www.nuget.org).

```bash
dotnet list package --outdated
```

Update any outdated packages that have newer versions with cross-platform support.

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime-only issues:

```bash
dotnet run --configuration Release
```

Pay attention to file path separators, line endings, and environment variable differences across platforms.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
# Framework-dependent (requires .NET runtime installed on target machine)
dotnet publish --configuration Release --output ./publish

# Self-contained (bundles the runtime)
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files are present before deploying.