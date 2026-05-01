# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other .NET Framework monikers unless a multi-targeting scenario is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved references.

### 3. Build the Solution
Perform a clean build to confirm there are no warnings that could indicate subtle issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility analyzers.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release
```

Review test output for any failures that may indicate behavioral differences introduced during the migration.

### 5. Check for Platform-Specific API Usage
Use the .NET Compatibility Analyzer or review code manually for any APIs that were available in .NET Framework but are not available or behave differently in cross-platform .NET. Common areas to check include:

- `System.Windows.Forms` or `System.Web` usage
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions (backslashes, drive letters)
- `AppDomain` usage
- `BinaryFormatter` (deprecated and disabled by default in modern .NET)

### 6. Verify Configuration and App Settings
If the project previously used `app.config` or `web.config`, confirm that settings have been migrated appropriately to `appsettings.json` or environment-based configuration using `Microsoft.Extensions.Configuration`.

### 7. Runtime Smoke Test
Run the application locally and exercise its primary functionality to confirm end-to-end behavior is correct:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

### 8. Publish the Application
Once validation is complete, publish the application for the target platform:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment target. Review the contents of the `publish` output folder before deploying.