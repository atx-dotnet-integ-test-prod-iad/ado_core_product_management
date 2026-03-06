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
Perform a full build to confirm the absence of errors is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that may indicate compatibility concerns even if they do not block the build.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences introduced by the framework migration rather than pre-existing failures.

### 5. Check for Windows-Specific API Usage
Even without build errors, the code may reference APIs that only function on Windows at runtime. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the build output for `CA1416` platform compatibility warnings, which indicate calls to Windows-only APIs.

### 6. Validate Runtime Behavior on Target Platforms
Run the application on each platform you intend to support (e.g., Linux, macOS, Windows) and verify that core functionality behaves as expected. Pay particular attention to:

- File path handling (`Path.Combine` vs. hardcoded separators)
- Registry access (Windows-only)
- `System.Drawing` usage (requires `libgdiplus` on Linux or migration to an alternative)
- Any P/Invoke calls to native Windows libraries

### 7. Review NuGet Package Compatibility
Cross-reference all packages listed in the `.csproj` files against [NuGet.org](https://www.nuget.org) to confirm they have versions that support your target framework. Replace any packages that have known cross-platform alternatives.

### 8. Publish a Self-Contained Build
Produce a self-contained publish output for each target runtime to confirm the application can be packaged correctly:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
dotnet publish --configuration Release --runtime win-x64 --self-contained true
```

Review the output directory to ensure all required assets are present.