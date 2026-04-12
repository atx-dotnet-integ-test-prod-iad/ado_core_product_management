# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Run a full solution build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that may indicate compatibility issues even if they do not block the build.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in globalization, file path handling, or reflection behavior).

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any APIs that are present but throw `PlatformNotSupportedException` at runtime on non-Windows platforms:

```bash
dotnet tool install -g dotnet-platform-compat
```

Pay particular attention to areas such as:
- `System.Drawing` (requires `libgdiplus` on Linux/macOS or replacement with `SkiaSharp`/`ImageSharp`)
- Windows Registry access (`Microsoft.Win32.Registry`)
- Windows-specific interop or COM components

### 6. Validate Configuration and App Settings
Confirm that any `App.config` or `Web.config` files have been properly migrated to `appsettings.json` or equivalent .NET configuration providers, and that the application reads settings correctly at runtime.

### 7. Verify Output Artifacts
After a successful Release build, inspect the output directory (`bin/Release/net8.0/` or equivalent) to confirm:
- The expected assemblies and dependencies are present.
- No extraneous `.config` transformation files from the legacy project remain.

### 8. Manual Smoke Testing
Run the application manually on each target platform (Windows, Linux, macOS as applicable) and exercise the primary workflows to catch any runtime issues that static analysis would not surface.

### 9. Review Nullable Reference Type Warnings
If the projects have `<Nullable>enable</Nullable>` set, review any nullable warnings in the build output. While these do not block compilation by default, they can indicate potential null-reference issues that should be addressed.

### 10. Publish a Self-Contained Build (Optional Validation)
To confirm the application is fully portable, produce a self-contained publish for a specific runtime identifier:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Verify the output runs correctly on the target platform without requiring a separately installed .NET runtime.