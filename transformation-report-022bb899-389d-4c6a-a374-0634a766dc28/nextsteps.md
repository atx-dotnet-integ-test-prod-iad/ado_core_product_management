# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other .NET Framework monikers unless a multi-targeting scenario is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm the clean state holds outside of the initial transformation context:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly `NU1701` (package compatibility) or `CS0618` (obsolete API usage), as these can indicate runtime risk even when the build succeeds.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify behavioral correctness has been preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate API behavioral differences between .NET Framework and modern .NET rather than simple compilation issues.

### 5. Check for Windows-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for APIs that are present in modern .NET but are Windows-only (annotated with `[SupportedOSPlatform("windows")]`). This is particularly relevant for `AdoCore` if it interacts with system-level or registry-level resources.

```bash
dotnet add package Microsoft.Windows.Compatibility
```

Only add this package if Windows-only APIs are required and cross-platform support for those code paths is not needed.

### 6. Validate Runtime Behavior
Run the application manually or through its entry point and exercise the primary workflows, particularly any that interact with:

- File system paths (ensure `Path.Combine` is used rather than hardcoded separators)
- Configuration files (confirm `appsettings.json` or equivalent is loading correctly)
- External dependencies or native libraries (confirm they have cross-platform builds available)

### 7. Review Nullable Reference Type Warnings
If the project was migrated from .NET Framework, nullable reference types may now surface warnings. Review the `.csproj` for:

```xml
<Nullable>enable</Nullable>
```

If this is enabled, address any `CS8600`–`CS8625` warnings to improve code correctness going forward.

### 8. Publish a Test Build
Produce a self-contained or framework-dependent publish output and verify it runs on the intended target platform:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` flag to match your deployment target (e.g., `win-x64`, `osx-x64`).