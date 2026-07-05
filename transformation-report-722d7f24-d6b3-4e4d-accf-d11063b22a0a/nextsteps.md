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
Perform a clean build to confirm there are no warnings that could indicate runtime issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failed or skipped tests and investigate accordingly.

### 5. Check for Platform-Specific API Usage
Use the .NET Compatibility Analyzer or review code manually for any APIs that are Windows-only. These will typically be annotated with `[SupportedOSPlatform("windows")]` warnings during build. If cross-platform support is required, replace or conditionally compile those APIs.

### 6. Verify Runtime Behavior
Run the application on each target platform (Windows, Linux, macOS as applicable) to confirm runtime behavior matches expectations:

```bash
dotnet run --configuration Release
```

Pay particular attention to file path handling, line endings, and any platform-specific environment assumptions in the code.

### 7. Review NuGet Package Compatibility
Check that all third-party NuGet packages support the target framework. You can inspect compatibility on [nuget.org](https://www.nuget.org) or by reviewing the `lib` folders inside the `.nupkg` files for the appropriate target framework moniker (TFM) folder.

### 8. Publish the Application
Once validation is complete, publish the application for the desired runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier (RID) for your target environment. Common RIDs include:
- `win-x64`
- `linux-x64`
- `osx-x64`
- `osx-arm64`

Review the publish output directory to confirm all required files are present before deploying.