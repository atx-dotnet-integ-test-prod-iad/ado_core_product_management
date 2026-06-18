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

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm there are no errors or warnings that were not captured previously:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify that existing behavior has been preserved after the transformation:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee correct runtime behavior.

### 5. Check for Windows-Specific API Usage
Since this was a legacy project being migrated to cross-platform .NET, audit the codebase for APIs that may compile successfully but fail at runtime on non-Windows platforms. Common areas to check include:

- `Microsoft.Win32` registry access
- `System.Windows.Forms` or `System.Drawing` (GDI+)
- P/Invoke calls to Windows-native DLLs
- File path separators (use `Path.Combine` and `Path.DirectorySeparatorChar`)

You can use the .NET Compatibility Analyzer to assist with this:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

### 6. Review Removed or Changed APIs
Check for any use of APIs that existed in .NET Framework but have been removed or changed in .NET. The [.NET Upgrade Assistant](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) and the official [.NET API compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) are useful references.

### 7. Validate Configuration and App Settings
If the project previously used `App.config` or `Web.config`, confirm that configuration has been migrated to `appsettings.json` or the appropriate .NET configuration model. Verify that all configuration values are being read correctly at runtime.

### 8. Manual Smoke Testing
Run the application manually and exercise the primary workflows to confirm that runtime behavior matches expectations from the original .NET Framework version.