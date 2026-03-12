# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless intentionally targeting multiple frameworks.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Resolve any warnings about deprecated or unlisted packages by updating them to their current equivalents.

### 3. Build the Solution
Perform a full build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Review any warnings that surface, as some may indicate runtime issues that do not block compilation.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify behavioral correctness after the transformation:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate platform-specific behavior that changed between .NET Framework and cross-platform .NET.

### 5. Check for Windows-Specific APIs
Even without build errors, some APIs may compile successfully but fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the official [.NET Upgrade Assistant compatibility reports](https://learn.microsoft.com/en-us/dotnet/core/porting/) for known problematic namespaces such as `System.Drawing`, `Microsoft.Win32`, or `System.Windows.Forms`.

### 6. Run the Application
Execute the main entry-point project directly to confirm runtime behavior:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Test all major code paths, particularly any database access, file I/O, or network communication, as these areas are most likely to surface cross-platform differences.

### 7. Review Configuration Files
Confirm that any `App.config` or `Web.config` files have been migrated to `appsettings.json` or equivalent .NET configuration providers where applicable, as the legacy XML-based configuration system has limited support in cross-platform .NET.

### 8. Verify Output Artifacts
Check the `bin/Release` output directory to confirm the expected assemblies, dependencies, and any publish profiles are producing the correct output:

```bash
dotnet publish --configuration Release
```

Review the published output to ensure no unintended files are missing or included.