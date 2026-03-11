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

Check the output for any warnings that may indicate compatibility issues that did not surface as hard errors.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in globalization, file path handling, or reflection behavior).

### 5. Check for Windows-Specific APIs
Even without build errors, some APIs may compile but fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code for usages of APIs such as `System.Drawing`, `Microsoft.Win32.Registry`, or anything under the `System.Windows` namespace, as these may not behave as expected on Linux or macOS.

### 6. Review Removed Configuration Files
Confirm that any `app.config` or `web.config` files have been migrated to the appropriate `appsettings.json` format and that configuration is being read using `Microsoft.Extensions.Configuration` where applicable.

### 7. Validate Output Artifacts
After a successful Release build, inspect the output directory (`bin/Release/net8.0/` or equivalent) to confirm:

- The expected assemblies and dependencies are present.
- No unintended `.dll` files from legacy references are included.
- The application runs as expected by executing the output directly:

```bash
dotnet AdoCore.dll
```

### 8. Test on Target Platforms
If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to catch any platform-specific runtime issues that static analysis may not detect.