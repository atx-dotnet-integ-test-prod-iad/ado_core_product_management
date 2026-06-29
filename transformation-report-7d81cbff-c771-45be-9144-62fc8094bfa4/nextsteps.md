# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `net472`, or any other .NET Framework moniker unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Run a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failed or skipped tests that may indicate behavioral differences between .NET Framework and the new target runtime.

### 5. Check for Platform-Specific API Usage
Use the .NET Compatibility Analyzer or the `Microsoft.DotNet.ApiCompat` tooling to identify any remaining usage of Windows-only or platform-specific APIs that may compile successfully but fail at runtime on non-Windows systems:

```bash
dotnet add package Microsoft.DotNet.ApiCompat
```

Pay particular attention to areas such as:
- Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) server-side APIs
- `System.Drawing` (GDI+)
- `System.Web` namespaces

### 6. Review NuGet Package Compatibility
Open the NuGet package manager or inspect each `.csproj` file and verify that all referenced packages have versions that explicitly support the target framework. Replace any packages that have known cross-platform replacements, for example:
- Replace `System.Drawing.Common` with a cross-platform imaging library if non-Windows support is required.
- Replace any remaining `Microsoft.AspNet.*` packages with their `Microsoft.AspNetCore.*` equivalents.

### 7. Validate Configuration Files
If the project previously used `app.config` or `web.config`, confirm that settings have been migrated to `appsettings.json` or environment-based configuration where appropriate, as `System.Configuration.ConfigurationManager` behavior differs in cross-platform .NET.

### 8. Perform Runtime Smoke Testing
Run the application locally and exercise the primary code paths to confirm there are no runtime exceptions that were not caught at compile time. Pay attention to:
- File path separators (`/` vs `\`)
- Case sensitivity on Linux file systems
- Environment variable differences across operating systems

## Deployment

Once validation is complete, publish the application using the following command, substituting the correct runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Common runtime identifiers include:
- `win-x64` — Windows 64-bit
- `linux-x64` — Linux 64-bit
- `osx-x64` — macOS Intel
- `osx-arm64` — macOS Apple Silicon

Review the contents of the `publish` output folder to confirm all required assets and dependencies are present before deploying to the target environment.