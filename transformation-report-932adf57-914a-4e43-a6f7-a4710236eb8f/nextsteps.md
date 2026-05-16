# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other outdated monikers unless intentionally targeting multiple frameworks.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if they do not produce build errors.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding further.

### 4. Check NuGet Package Compatibility
Review all NuGet dependencies in each `.csproj` file. Confirm that every package version is compatible with the target framework. You can use the following command to identify outdated packages:

```bash
dotnet list package --outdated
```

Update packages where newer, compatible versions are available.

### 5. Review Removed or Changed APIs
Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any calls to APIs that exist in .NET Framework but are absent or behave differently in cross-platform .NET. Pay particular attention to:

- `System.Web` usages (not available in .NET Core/.NET 5+)
- Windows-specific APIs (registry, WCF server-side, etc.)
- `AppDomain`, `BinaryFormatter`, and `Remoting` APIs

### 6. Validate Runtime Behavior on Target Platforms
If the goal is cross-platform execution, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues:

```bash
dotnet run --configuration Release
```

### 7. Review Output Artifacts
Confirm that the build produces the expected output types (executable, class library, etc.) by inspecting the `bin/Release` directory after building. Verify that all expected assemblies and their dependencies are present.

### 8. Publish a Self-Contained or Framework-Dependent Build
Once validation is complete, produce a publish artifact to confirm the deployment package is correct:

```bash
# Framework-dependent
dotnet publish --configuration Release --output ./publish

# Self-contained (example for Linux x64)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish-linux
```

Inspect the output directory to ensure all required files are present and no unresolved native dependencies are missing.