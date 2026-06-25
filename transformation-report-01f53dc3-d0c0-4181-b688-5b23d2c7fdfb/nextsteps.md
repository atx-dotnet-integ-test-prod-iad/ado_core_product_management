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
Review the output for any warnings that may indicate deprecated APIs or packages that should be addressed.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not changed:
```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```
Review any failing tests and determine whether they are caused by behavioral differences between .NET Framework and modern .NET.

### 4. Review NuGet Package Compatibility
Open each `.csproj` and review `<PackageReference>` entries. Check that all packages:
- Have versions compatible with the target framework.
- Are not marked as deprecated on [nuget.org](https://www.nuget.org).
- Do not have known replacements (e.g., `System.Web` dependencies replaced by `Microsoft.AspNetCore` equivalents).

### 5. Check for Removed or Changed APIs
Run the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.ApiCompat` tool to surface any API usage that may compile but behave differently at runtime:
```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <solution>.sln
```

### 6. Review Platform-Specific Code
Search the codebase for any platform-specific assumptions such as:
- Windows registry access (`Microsoft.Win32.Registry`)
- Windows-only file path separators
- P/Invoke calls targeting Windows-only native libraries

Use `RuntimeInformation.IsOSPlatform()` guards where platform-specific code must be retained.

### 7. Validate Configuration Files
If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables where appropriate, as `System.Configuration` support is limited in modern .NET.

### 8. Smoke Test the Application
Run the application in a local environment and exercise its primary workflows to confirm end-to-end behavior is consistent with the original .NET Framework version.

```bash
dotnet run --project src/AdoCore/AdoCore.csproj --configuration Release
```

### 9. Review Output Artifacts
Confirm the build output directory contains the expected assemblies and that no unintended dependencies on platform-specific runtimes exist in the published output:
```bash
dotnet publish --configuration Release --output ./publish
```
Inspect the `./publish` folder to verify the contents are as expected.