# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this is consistent across all projects in the solution, particularly `AdoCore.csproj` and any projects that depend on it.

### 2. Restore Dependencies
Run a full NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build of the entire solution:

```bash
dotnet clean
dotnet build
```

Confirm there are zero errors and review any warnings, particularly those related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test
```

Review test results carefully. A successful build does not guarantee correct runtime behavior.

### 5. Check for Platform-Specific Code
Search the codebase for any APIs that were previously Windows-only and may now produce `PlatformNotSupportedException` at runtime on non-Windows platforms. Common areas to check include:

- `Microsoft.Win32` registry access
- `System.Drawing` (GDI+)
- Windows Communication Foundation (WCF) server-side APIs
- `System.Security.Permissions` and related CAS APIs

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package to surface these issues statically.

### 6. Review Removed or Changed APIs
Cross-reference the project's usage of any APIs that were removed or had behavioral changes in .NET. The official [.NET breaking changes documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/breaking-changes) is the authoritative reference for this.

### 7. Validate Configuration and App Settings
If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or the appropriate .NET configuration provider. Verify that connection strings, logging configuration, and environment-specific settings load correctly at runtime.

### 8. Manual Smoke Testing
Run the application manually and exercise the primary workflows to confirm end-to-end behavior matches the legacy version. Pay particular attention to:

- Data access and database connectivity
- Authentication and authorization flows
- Any interop with COM components or native libraries

## Deployment

### 1. Choose a Publish Profile
Decide between a framework-dependent deployment and a self-contained deployment:

```bash
# Framework-dependent
dotnet publish -c Release -f net8.0

# Self-contained (example for Windows x64)
dotnet publish -c Release -f net8.0 -r win-x64 --self-contained true
```

### 2. Verify Published Output
Inspect the contents of the `publish` output folder to confirm all required assemblies, configuration files, and static assets are present.

### 3. Test the Published Output
Run the published output directly on a target machine (or a clean environment that mirrors production) before promoting it to production. This catches issues such as missing runtime dependencies or incorrect file paths that may not surface during local development.