# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:
```xml
<TargetFramework>net8.0</TargetFramework>
```
Ensure no projects are still referencing `net4x` or `netstandard` targets unless that is intentional.

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
Review any failing tests and trace them back to behavioral differences introduced by the framework migration.

### 4. Audit NuGet Package Compatibility
Check that all NuGet packages referenced in each `.csproj` are compatible with the target framework. You can use the following command to identify outdated or potentially incompatible packages:
```bash
dotnet list package --outdated
```
Replace any packages that have known .NET-compatible alternatives, particularly those that were designed for .NET Framework only.

### 5. Review Removed or Changed APIs
Cross-platform .NET removes or changes certain APIs that existed in .NET Framework. Review the code for usage of the following common problem areas:
- `System.Web` (not available in .NET Core/.NET 5+)
- `AppDomain` members with limited support
- Windows Registry access (`Microsoft.Win32.Registry`)
- `BinaryFormatter` (deprecated and disabled by default)
- `System.Drawing` on non-Windows platforms (use `System.Drawing.Common` with awareness of platform limitations)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.ApiCompat` tooling to systematically surface these issues.

### 6. Verify Platform-Specific Behavior
If the application is intended to run cross-platform (Windows, Linux, macOS), test it on each target platform. Pay particular attention to:
- File path separators (`\` vs `/`)
- Case sensitivity in file system operations
- Platform-specific native interop or P/Invoke calls

### 7. Check Configuration and Environment
Confirm that any configuration previously handled by `app.config` or `web.config` has been migrated to `appsettings.json` or environment variables, and that the application reads these correctly at runtime using `Microsoft.Extensions.Configuration`.

### 8. Publish the Application
Once validation is complete, publish the application using:
```bash
dotnet publish --configuration Release --output ./publish
```
Review the output directory to confirm all required files and dependencies are present. For a self-contained deployment, add:
```bash
--self-contained true --runtime <runtime-identifier>
```
For example, `--runtime win-x64` or `--runtime linux-x64`.