# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

### 2. Restore Dependencies
Run a full NuGet restore to ensure all packages resolve correctly against the new target framework:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not fully support the target framework (look for `NU1701` or similar warnings).

### 3. Build the Solution
Perform a clean build to confirm there are no errors or warnings that were not caught during the initial transformation review:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

### 4. Run Existing Tests
If the solution contains test projects, execute the full test suite to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime (e.g., differences in globalization, threading, or reflection behavior).

### 5. Review Platform-Specific Code
Search the codebase for any APIs that were available in .NET Framework but have known behavioral differences or are unsupported in cross-platform .NET. Common areas to check include:

- `System.Drawing` (requires the `System.Drawing.Common` package and may have OS restrictions)
- `System.Windows.Forms` or `System.Web` (not supported on non-Windows platforms)
- Registry access (`Microsoft.Win32.Registry`)
- COM interop or P/Invoke calls
- `AppDomain` usage beyond the single default domain

### 6. Check Configuration Files
If the project previously relied on `app.config` or `web.config`, verify that configuration has been migrated appropriately. Cross-platform .NET uses `appsettings.json` and the `Microsoft.Extensions.Configuration` stack by default.

### 7. Runtime Smoke Test
Run the application manually and exercise the primary code paths to confirm expected behavior end-to-end before proceeding to any broader deployment.

## Deployment

### 1. Publish the Application
Use the `dotnet publish` command to produce the deployment artifact:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment (no .NET runtime required on the target machine):

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier for your target environment (e.g., `linux-x64`, `osx-x64`).

### 2. Verify the Published Output
Inspect the `./publish` directory to confirm all expected assemblies, configuration files, and static assets are present.

### 3. Test on the Target Environment
Deploy the published output to a staging environment that matches production and run the application there before final deployment. Pay particular attention to file path separators, environment variables, and any OS-specific behavior if deploying to a non-Windows host.