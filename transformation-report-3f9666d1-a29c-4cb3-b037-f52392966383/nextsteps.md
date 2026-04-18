# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:
```xml
<TargetFramework>net8.0</TargetFramework>
```
Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional.

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
Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET.

### 4. Review NuGet Package Compatibility
Check that all NuGet dependencies are compatible with the target framework. You can use the following command to inspect outdated or potentially incompatible packages:
```bash
dotnet list package --outdated
```
Replace any packages that do not support the new target framework with their modern equivalents.

### 5. Check for Removed or Changed APIs
Some APIs available in .NET Framework are not present or behave differently in cross-platform .NET. Review the [.NET Upgrade Assistant compatibility analyzer results](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or run the compatibility analyzer:
```bash
dotnet add package Microsoft.DotNet.UpgradeAssistant.Extensions.Default.Analyzers
dotnet build
```
Address any analyzer warnings related to platform compatibility.

### 6. Validate Platform-Specific Behavior
If the project uses any of the following, verify they behave correctly on the target platform:
- File system paths (use `Path.Combine` and avoid hardcoded separators)
- Registry access (not available on Linux/macOS)
- Windows-specific APIs such as `System.Drawing` or `System.Windows.Forms`
- `app.config` or `web.config` (replaced by `appsettings.json` in modern .NET)

### 7. Run the Application
Execute the application directly to confirm it starts and operates as expected:
```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```
Test the primary workflows and verify outputs match the expected behavior from the original .NET Framework version.

## Deployment Steps

### 1. Publish a Self-Contained or Framework-Dependent Build
Choose a publish profile appropriate for your deployment target.

**Framework-dependent** (requires .NET runtime installed on the target machine):
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained** (bundles the runtime, no installation required on target):
```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```
Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) for your target environment.

### 2. Verify the Published Output
Navigate to the `./publish` directory and confirm all expected binaries, configuration files, and assets are present before deploying to the target environment.