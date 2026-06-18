# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:
```xml
<TargetFramework>net8.0</TargetFramework>
```

### 2. Restore NuGet Packages
Run the following command from the solution root to ensure all dependencies are restored cleanly:
```bash
dotnet restore
```
Review the output for any warnings about deprecated or unlisted packages and consider updating them.

### 3. Build the Solution
Perform a full build to confirm there are no errors in the restored state:
```bash
dotnet build --configuration Release
```

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:
```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```
Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 5. Review Removed or Replaced APIs
Check the code for any APIs that were available in .NET Framework but have changed behavior in cross-platform .NET. Common areas to review include:
- `System.Configuration` — replaced by `Microsoft.Extensions.Configuration`
- `System.Web` — not available outside of Windows; replaced by `Microsoft.AspNetCore`
- Windows Registry access (`Microsoft.Win32.Registry`) — only functional on Windows
- `AppDomain` — some members are no longer supported
- Serialization via `BinaryFormatter` — disabled by default and considered obsolete

### 6. Run the Application
Execute the application directly and exercise its primary workflows to confirm correct runtime behavior:
```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

### 7. Check Platform-Specific Behavior
If the project uses any Windows-specific functionality (COM interop, WinForms, WPF, P/Invoke, etc.), verify that the target runtime identifier is set appropriately in the `.csproj` if cross-platform support is not required:
```xml
<RuntimeIdentifier>win-x64</RuntimeIdentifier>
```
If true cross-platform support is needed, audit those code paths and replace or guard them accordingly.

### 8. Review Warnings
Even with a clean build, review any compiler warnings produced during the build step. Warnings related to nullable reference types, obsolete APIs, or platform compatibility attributes may indicate areas that require attention before the project is considered fully modernized.