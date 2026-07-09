# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:
```xml
<TargetFramework>net8.0</TargetFramework>
```
Ensure no projects are still referencing `net4x` or `netstandard` frameworks unless that is intentional.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:
```bash
dotnet restore
dotnet build --configuration Release
```
Review the output for any warnings that may indicate deprecated APIs or compatibility concerns even if the build succeeds.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not changed:
```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```
Review any failing tests carefully, as they may indicate behavioral differences between the old .NET Framework runtime and the new cross-platform .NET runtime.

### 4. Check for Removed or Changed APIs
Even with a successful build, some APIs behave differently on cross-platform .NET. Pay particular attention to:
- `System.Web` usages (not available on .NET Core/.NET 5+)
- Windows-specific APIs such as the registry, WMI, or certain `System.Drawing` features
- `AppDomain`, `BinaryFormatter`, and `Remoting` APIs which are removed or restricted

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to surface any remaining compatibility issues.

### 5. Validate NuGet Package Versions
Open the solution's `packages.config` or `<PackageReference>` entries and confirm all NuGet dependencies have versions compatible with your target framework. Run:
```bash
dotnet list package --outdated
```
Update packages where appropriate, particularly any that previously targeted only .NET Framework.

### 6. Test on Target Platforms
Since the goal is cross-platform support, run the application on each intended platform (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear at compile time:
```bash
dotnet run --configuration Release
```

### 7. Review Output Artifacts
Confirm the build output in the `bin/Release` folder contains the expected assemblies and that no unintended `.exe` wrappers or platform-specific binaries are present unless they are required.

### 8. Publish a Release Build
Once validation is complete, produce a published output to confirm the deployment artifact is correct:
```bash
dotnet publish --configuration Release --output ./publish
```
Review the contents of the `./publish` folder to ensure all required files, dependencies, and assets are present.