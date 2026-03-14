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
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Run a full solution build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Review any warnings that surface during the build, as some warnings may indicate compatibility concerns that do not block compilation but could cause runtime issues.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify that runtime behavior is consistent with the pre-migration state:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences between .NET Framework and cross-platform .NET (for example, differences in globalization, reflection, or threading).

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to scan for any APIs that are present in .NET but throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Run the following if the analyzer is available:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

Pay particular attention to areas such as:
- Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) server-side APIs
- `System.Drawing` (GDI+ dependent code)
- `System.Security.Permissions`

### 6. Validate Configuration Files
If the project previously relied on `app.config` or `web.config`, confirm that settings have been migrated to `appsettings.json` or the appropriate .NET configuration model. Verify that connection strings, logging configuration, and environment-specific settings load correctly at runtime.

### 7. Perform a Runtime Smoke Test
Run the application locally and exercise the primary code paths to confirm that the application behaves as expected. Compare outputs or behavior against the legacy .NET Framework version where possible.

### 8. Review Removed or Changed APIs
Consult the [.NET breaking changes documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/breaking-changes) for the specific version you are targeting to identify any APIs that were removed or changed in behavior. Cross-reference these against the codebase to ensure nothing was silently broken.

### 9. Deployment
Once the above steps are completed and the application is stable:

1. Publish the application using:
   ```bash
   dotnet publish --configuration Release --output ./publish
   ```
2. Confirm that the output directory contains all required runtime files.
3. If publishing a self-contained executable, include the runtime identifier:
   ```bash
   dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
   ```
4. Deploy the contents of the `./publish` directory to the target environment and verify the application starts and operates correctly.