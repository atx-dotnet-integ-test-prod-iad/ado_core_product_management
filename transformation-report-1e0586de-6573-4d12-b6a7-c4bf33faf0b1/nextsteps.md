# Next Steps

The solution appears to have transformed successfully — no build errors were reported across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other outdated monikers unless intentionally targeting multiple frameworks.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that could not be resolved.

### 3. Build the Solution
Perform a clean build to confirm there are no lingering issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify functional correctness after the transformation:

```bash
dotnet test --configuration Release
```

Review test results carefully. A passing build does not guarantee runtime correctness, so test coverage is important here.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any remaining Windows-specific API calls that may compile successfully but fail at runtime on Linux or macOS. You can also enable the platform compatibility analyzer by ensuring this is present in your `.csproj`:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

### 6. Review NuGet Package Versions
Check that all NuGet dependencies have versions compatible with the target framework. Run:

```bash
dotnet list package --outdated
```

Update packages where appropriate, particularly any that previously had `.NET Framework`-only versions and now have cross-platform alternatives.

### 7. Validate Runtime Behavior
Run the application locally on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement. Pay particular attention to:

- File path separators (`\` vs `/`)
- Environment variable access
- Registry access (Windows-only, will fail on other platforms)
- `System.Drawing` usage (requires additional native dependencies on Linux/macOS)

### 8. Publish the Application
Once validation is complete, publish the application for the target runtime(s):

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) as needed. Review the publish output directory to confirm all required assets are present.