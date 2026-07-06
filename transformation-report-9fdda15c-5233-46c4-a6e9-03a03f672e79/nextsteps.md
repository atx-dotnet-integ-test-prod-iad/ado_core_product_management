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
Run the following commands from the solution root to confirm a clean restore and build:
```bash
dotnet restore
dotnet build --configuration Release
```
Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not changed:
```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```
Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and modern .NET.

### 4. Review NuGet Package Compatibility
Open each `.csproj` and check that all `<PackageReference>` entries reference versions that are compatible with the target framework. You can use the following command to check for outdated packages:
```bash
dotnet list package --outdated
```
Replace any packages that have known .NET Framework-only dependencies with their cross-platform equivalents.

### 5. Check for Removed or Changed APIs
Some APIs available in .NET Framework are not present or behave differently in modern .NET. Review the [.NET Upgrade Assistant compatibility analyzer results](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or run the compatibility analyzer manually:
```bash
dotnet add package Microsoft.DotNet.UpgradeAssistant.Extensions.Default.Analyzers
dotnet build
```
Address any analyzer warnings related to platform compatibility.

### 6. Validate Runtime Behavior
Execute the application and step through its primary workflows to confirm that behavior matches the original .NET Framework version. Pay particular attention to:
- File I/O paths, as path separator behavior differs on Linux and macOS.
- Registry access, which is Windows-only and will fail on other platforms.
- Windows Communication Foundation (WCF) client/server usage, which has limited support in modern .NET.
- `System.Drawing` usage, which requires the `System.Drawing.Common` package and is restricted on non-Windows platforms.

### 7. Check Platform-Specific Code
Search the codebase for any `#if` preprocessor directives or `RuntimeInformation.IsOSPlatform` checks to ensure platform-specific branches are correct and complete for all intended target operating systems.

### 8. Review `app.config` / `web.config` Migration
If the original project used `app.config` or `web.config`, confirm that settings have been migrated to `appsettings.json` or the appropriate modern .NET configuration model. Legacy config files are not fully supported in modern .NET.

### 9. Publish a Release Build
Once the above steps are completed, produce a published output to verify the final artifact:
```bash
dotnet publish --configuration Release --output ./publish
```
Inspect the `./publish` directory to confirm all expected binaries and dependencies are present.