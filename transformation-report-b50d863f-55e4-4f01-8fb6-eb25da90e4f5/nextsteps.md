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

Review the output for any warnings about deprecated packages or packages that lack cross-platform support.

### 3. Build the Solution
Run a full build to confirm there are no warnings that could indicate runtime issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility analyzers (`CA1416`).

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review test output for any failures or skipped tests that may indicate platform-specific behavior that was not accounted for during transformation.

### 5. Check for Platform-Specific API Usage
Use the .NET Compatibility Analyzer to identify any remaining Windows-specific API calls. The analyzer will emit `CA1416` warnings for APIs that are not supported on all platforms. If certain code paths are intentionally Windows-only, annotate them with:

```csharp
[System.Runtime.Versioning.SupportedOSPlatform("windows")]
```

### 6. Verify Runtime Behavior
Run the application on each target platform (Windows, Linux, macOS) to confirm runtime behavior is consistent. Pay particular attention to:

- File path handling (`Path.Combine` vs hardcoded separators)
- Environment variable access
- Registry access (Windows-only; should be abstracted or removed)
- `System.Drawing` usage (requires `libgdiplus` on Linux/macOS or migration to an alternative library)

### 7. Review NuGet Package Compatibility
Check that all third-party NuGet packages support the target framework. Visit [nuget.org](https://www.nuget.org) for each dependency and confirm `.NET 6`, `.NET 7`, or `.NET 8` target framework assets are available.

### 8. Publish the Application
Once validation is complete, publish the application for the desired runtime targets:

```bash
# Framework-dependent
dotnet publish --configuration Release

# Self-contained for a specific runtime
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Review the publish output directory to confirm all expected files are present.