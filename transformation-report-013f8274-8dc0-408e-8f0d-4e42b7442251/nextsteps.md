# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless multi-targeting is intentional.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding further.

### 4. Check NuGet Package Compatibility
Review all NuGet dependencies and confirm they support the target framework. You can use the following command to identify outdated packages:

```bash
dotnet list package --outdated
```

Replace any packages that do not have a compatible version with supported alternatives.

### 5. Review for Windows-Specific APIs
Even without build errors, the code may contain Windows-specific API calls (e.g., registry access, `System.Windows.Forms`, COM interop) that will fail at runtime on non-Windows platforms. Search the codebase for usages of:

- `Microsoft.Win32`
- `System.Windows.Forms`
- `System.Drawing` (non-cross-platform variant)
- P/Invoke calls targeting Windows DLLs

Use the [Platform Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to assist with this.

### 6. Validate Configuration and App Settings
Confirm that any configuration files (e.g., `app.config`, `web.config`) have been migrated to the appropriate .NET format such as `appsettings.json` or environment-based configuration. Legacy `.config` files are not fully supported in cross-platform .NET.

### 7. Test on Target Platforms
Run and test the application on each platform you intend to support (Linux, macOS, Windows) to surface any platform-specific runtime issues that static analysis would not catch:

```bash
dotnet run --configuration Release
```

### 8. Publish the Application
Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# Framework-dependent
dotnet publish --configuration Release --output ./publish

# Self-contained for a specific platform
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the output directory to confirm all required assets are present before deployment.