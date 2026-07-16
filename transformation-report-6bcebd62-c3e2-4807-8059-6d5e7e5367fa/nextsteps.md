# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional for multi-targeting.

### 2. Restore and Build Locally
Run the following commands from the root of the solution to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET.

### 4. Check for Removed or Changed APIs
Review the code for usage of APIs that were removed or changed in cross-platform .NET. The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the [Platform Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) can assist with identifying these at compile time.

Common areas to check include:
- `System.Web` usages (not available on cross-platform .NET)
- Windows-specific APIs (e.g., registry access, WCF server-side, Windows Forms if targeting non-Windows)
- `BinaryFormatter` usage, which is disabled by default in .NET 5+
- `AppDomain.CreateDomain`, which is no longer supported

### 5. Verify NuGet Package Compatibility
Check that all NuGet packages referenced in the project files support the target framework. You can inspect this in the `packages.lock.json` or by reviewing package pages on [nuget.org](https://www.nuget.org) for supported frameworks.

Run the following to list outdated packages:

```bash
dotnet list package --outdated
```

Update packages where newer versions provide cross-platform .NET support.

### 6. Test on Target Operating Systems
If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to catch any platform-specific runtime issues that would not surface during a build.

```bash
dotnet run --configuration Release
```

### 7. Review Output Artifacts
Confirm that the build output in the `bin/Release` folder contains the expected assemblies and that no legacy `.config` files (such as `app.config` or `web.config`) are being relied upon in ways incompatible with cross-platform .NET configuration patterns. Migrate any such configuration to `appsettings.json` with `Microsoft.Extensions.Configuration` if not already done.

### 8. Publish a Test Build
Perform a test publish to verify the deployment output is complete:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` folder to confirm all required files are present and the application runs correctly from that output directory.