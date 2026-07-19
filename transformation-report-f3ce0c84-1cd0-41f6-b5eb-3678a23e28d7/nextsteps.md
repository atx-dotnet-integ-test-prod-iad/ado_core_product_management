# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this is consistent across all projects in the solution, particularly `AdoCore.csproj` and any projects that depend on it.

### 2. Restore NuGet Packages
Run the following command from the solution root to confirm all dependencies resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts.

### 3. Build the Solution
Perform a full build to confirm there are no errors or warnings that were not surfaced previously:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or obsolete API usage.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify that behavior has not changed during the transformation:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated before proceeding.

### 5. Check for Removed Windows-Specific APIs
Even without build errors, some APIs that compiled successfully may not behave correctly on non-Windows platforms at runtime. Review the code for usage of:

- `Microsoft.Win32` registry APIs
- `System.Windows.Forms` or `System.Drawing` (unless the `EnableWindowsTargeting` or compatibility packages are referenced)
- P/Invoke calls to Windows-native DLLs
- `Environment.SpecialFolder` paths that differ across platforms

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package if cross-platform path handling is needed.

### 6. Review Configuration and App Settings
If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables, as `ConfigurationManager` behavior differs in .NET compared to .NET Framework.

### 7. Verify Runtime Behavior
Run the application manually against a representative set of inputs or scenarios. Pay particular attention to:

- File I/O paths (use `Path.Combine` and avoid hardcoded backslashes)
- Serialization behavior, as `Newtonsoft.Json` and `System.Text.Json` have differences
- Any reflection-based code that may be affected by trimming or assembly loading changes

### 8. Review Package Versions
Check that all NuGet packages referenced in the `.csproj` files are up to date and have .NET-compatible versions:

```bash
dotnet list package --outdated
```

Update packages where appropriate, and review changelogs for any breaking changes.