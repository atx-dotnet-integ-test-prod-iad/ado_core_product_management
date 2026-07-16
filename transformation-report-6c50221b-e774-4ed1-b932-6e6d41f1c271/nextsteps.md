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

Resolve any warnings about deprecated or unlisted packages by updating them in the relevant `.csproj` files.

### 3. Build the Solution
Perform a full build to confirm there are no warnings that could indicate runtime issues:

```bash
dotnet build --configuration Release
```

Review any remaining warnings, particularly those related to nullable reference types, platform compatibility (`CA1416`), or obsolete APIs.

### 4. Run the Test Suite
If the solution contains test projects, execute them to validate functional correctness:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Investigate any failing tests, as they may indicate behavioral differences introduced by the migration to cross-platform .NET.

### 5. Check for Windows-Specific API Usage
Even without build errors, certain APIs may compile successfully but fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to any uses of:
- `Microsoft.Win32` registry APIs
- `System.Windows.Forms` or `System.Drawing` (GDI+)
- P/Invoke calls into Windows-native DLLs
- `System.Security.Permissions` types that have been stubbed out in .NET Core and later

### 6. Validate Runtime Behavior
Run the application on each target platform (Windows, Linux, macOS) if cross-platform execution is a stated goal. Confirm that file paths, line endings, environment variable access, and culture-sensitive operations behave as expected across platforms.

### 7. Review `AdoCore.csproj` Specifically
Since `AdoCore` is the most independent project in the dependency graph, validate it in isolation first:

```bash
dotnet build src/AdoCore/AdoCore.csproj --configuration Release
dotnet test src/AdoCore.Tests/AdoCore.Tests.csproj --configuration Release
```

Adjust the paths above to match your actual solution structure.

### 8. Update NuGet Packages
Check for outdated packages across the solution:

```bash
dotnet list package --outdated
```

Update packages where appropriate, particularly any that were carried over from the legacy project and may have newer cross-platform compatible versions available.