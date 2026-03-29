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
Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they are not hard errors.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not changed:
```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```
Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and the new .NET runtime.

### 4. Check for Removed or Changed APIs
Even without build errors, some APIs behave differently on cross-platform .NET. Pay particular attention to:
- Any code using `System.Web` (not available on .NET Core/.NET 5+)
- Windows-specific APIs such as the registry, WCF, or Windows Forms (if the project is intended to be cross-platform)
- `AppDomain`, `BinaryFormatter`, or `Remoting` usage, which are either removed or obsolete

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` NuGet package to identify any remaining compatibility issues.

### 5. Review NuGet Package Versions
Open the `.csproj` files and verify that all NuGet package references are targeting versions compatible with your new target framework. Run:
```bash
dotnet list package --outdated
```
Update packages where appropriate, and confirm no packages are pulling in `net45` or `net48` dependencies that could cause runtime issues.

### 6. Test on Target Platforms
If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear at compile time.

### 7. Review Configuration Files
Check that any `app.config` or `web.config` files have been migrated to `appsettings.json` or the appropriate .NET configuration model. Legacy XML-based configuration is not fully supported in cross-platform .NET.

## Deployment

### 1. Publish the Application
Use the `dotnet publish` command to produce a deployment artifact:
```bash
dotnet publish --configuration Release --output ./publish
```
For a self-contained deployment that does not require the .NET runtime to be installed on the target machine:
```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```
Replace `win-x64` with the appropriate runtime identifier for your target environment (e.g., `linux-x64`, `osx-x64`).

### 2. Verify the Published Output
Navigate to the `./publish` directory and confirm all expected files are present, including configuration files, static assets, and any native dependencies.

### 3. Smoke Test the Published Artifact
Run the published artifact directly on the target machine or environment before considering the deployment complete:
```bash
./AdoCore
```
or on Windows:
```bash
AdoCore.exe
```
Confirm the application starts and behaves as expected under realistic conditions.