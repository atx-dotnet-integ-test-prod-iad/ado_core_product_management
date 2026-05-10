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

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm the absence of errors is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Also build in `Debug` configuration:

```bash
dotnet build --configuration Debug
```

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review test output carefully. A successful build does not guarantee correct runtime behavior.

### 5. Check for Platform-Specific APIs
Search the codebase for APIs that are known to be Windows-only, such as those in the following namespaces:

- `Microsoft.Win32`
- `System.Windows.Forms`
- `System.Drawing` (GDI+ based)
- `System.Runtime.InteropServices` (P/Invoke calls to Windows DLLs)

If any are found and cross-platform support is required, those APIs will need to be replaced or conditionally compiled using runtime checks:

```csharp
if (OperatingSystem.IsWindows())
{
    // Windows-specific code
}
```

### 6. Review NuGet Package Compatibility
Run the following command to check for any outdated or incompatible packages:

```bash
dotnet list package --outdated
```

Replace any packages that do not have a version compatible with your target framework.

### 7. Validate Configuration Files
Check that any configuration files (e.g., `app.config`, `web.config`) have been migrated to the appropriate format for .NET, typically `appsettings.json` with `Microsoft.Extensions.Configuration`. Legacy XML-based config files are not fully supported in cross-platform .NET.

### 8. Test on Target Platforms
If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that would not appear at compile time:

```bash
dotnet run --configuration Release
```

### 9. Publish the Application
Once validation is complete, publish the application for the target runtime. For a self-contained deployment targeting Linux x64 as an example:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

For a framework-dependent deployment:

```bash
dotnet publish --configuration Release
```

Review the output directory to confirm all expected files are present before deploying to the target environment.