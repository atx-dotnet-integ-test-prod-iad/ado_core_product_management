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
Run the following command from the solution root to confirm all NuGet packages resolve without issue:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Run a full build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that may indicate compatibility issues that did not surface as hard errors.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in globalization, reflection, or file path handling).

### 5. Check for Windows-Specific API Usage
Even without build errors, certain APIs may compile successfully but fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these issues:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code for usages of:
- `Microsoft.Win32` registry APIs
- `System.Windows.Forms` or `System.Drawing` (GDI+)
- P/Invoke calls to Windows-specific native libraries
- `System.Security.Permissions` types that behave differently on cross-platform .NET

### 6. Review `App.config` / `Web.config` Migrations
If the original project used `App.config` or `Web.config`, confirm that settings have been properly migrated to `appsettings.json` or equivalent configuration mechanisms supported by `Microsoft.Extensions.Configuration`.

### 7. Validate Runtime Behavior
Run the application directly and exercise its primary workflows:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Pay particular attention to:
- Database connectivity and ADO.NET behavior, given the project name suggests ADO usage
- Connection string formats, which may differ between providers on cross-platform .NET
- Any `System.Data` functionality that may have changed between .NET Framework and .NET

### 8. Review NuGet Package Versions
Confirm that all third-party NuGet packages in use have versions that explicitly support the target framework. Check each package on [nuget.org](https://www.nuget.org) if there is any uncertainty.