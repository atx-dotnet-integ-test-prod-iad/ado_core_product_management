# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:
```xml
<TargetFramework>net8.0</TargetFramework>
```
Ensure no projects are still referencing `net4x` or `netstandard` unless that is intentional.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:
```bash
dotnet restore
dotnet build --configuration Release
```
Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify that behavior has not changed after the migration:
```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```
Review any failing tests and trace them back to API or behavioral differences between the old and new framework.

### 4. Audit NuGet Package Compatibility
Check that all NuGet packages referenced in each `.csproj` are compatible with the target framework. You can use the following command to identify outdated or potentially incompatible packages:
```bash
dotnet list package --outdated
```
For any packages that are incompatible, search for their cross-platform equivalents on [nuget.org](https://www.nuget.org).

### 5. Review Removed or Changed APIs
Some APIs available in .NET Framework are not present or have changed in cross-platform .NET. Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the [Platform Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to surface any runtime-level concerns that do not produce build errors.

### 6. Test on Target Platforms
If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to catch any platform-specific issues such as:
- File path separator differences (`\` vs `/`)
- Case-sensitive file systems on Linux
- Platform-specific APIs that compile but fail at runtime

### 7. Publish the Application
Once validation is complete, publish the application using:
```bash
dotnet publish --configuration Release --output ./publish
```
Review the contents of the `./publish` directory to confirm all required files and dependencies are present. For a self-contained deployment, add:
```bash
--self-contained true --runtime <runtime-identifier>
```
For example, `--runtime linux-x64` or `--runtime win-x64`.