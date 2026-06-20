# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other Windows-only framework monikers unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm there are no issues that were not surfaced previously:

```bash
dotnet build --configuration Release
```

Review all warnings in the output, as some warnings may indicate compatibility issues that do not prevent compilation but could cause runtime problems.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

### 5. Check for Windows-Specific API Usage
Even if the project builds successfully, it may still contain APIs that only function correctly on Windows. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the build output for `CA1416` platform compatibility warnings, which indicate Windows-specific API calls.

### 6. Verify Runtime Behavior on Target Platforms
Run the application on each platform you intend to support (Windows, Linux, macOS) and confirm that core functionality behaves as expected. Pay particular attention to:

- File path handling (`Path.Combine` vs hardcoded separators)
- Registry access (Windows-only)
- `System.Drawing` usage (requires additional packages on non-Windows)
- Any P/Invoke or interop code

### 7. Review Removed or Changed APIs
Cross-reference your codebase against the [.NET Upgrade Assistant compatibility reports](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the [.NET API compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) to identify any APIs that behave differently in modern .NET.

### 8. Publish the Application
Once validation is complete, publish the application for your target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) for your deployment target. Review the published output directory to confirm all required assets are present.