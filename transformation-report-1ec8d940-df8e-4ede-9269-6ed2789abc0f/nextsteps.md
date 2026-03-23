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
Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Review any warnings that surface during the build, as some may indicate compatibility issues that did not produce hard errors.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review test output carefully, paying attention to any tests that were previously passing and are now failing.

### 5. Check for Windows-Specific API Usage
Even when a project compiles successfully, it may contain calls to Windows-specific APIs that will fail at runtime on other platforms. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the build output for `CA1416` platform compatibility warnings.

### 6. Verify Runtime Behavior on Target Platforms
Run the application on each platform you intend to support (e.g., Linux, macOS, Windows) to confirm there are no platform-specific runtime failures, particularly around:

- File path separators
- Registry access
- Windows-only libraries (e.g., `System.Drawing.Common` on Linux)
- P/Invoke calls

### 7. Review `app.config` / `web.config` Migrations
If the original project used `app.config` or `web.config`, confirm that configuration has been migrated to `appsettings.json` or another supported mechanism, and that the application reads configuration correctly at runtime.

### 8. Publish a Release Build
Once the above steps pass, produce a published output to verify the final artifact:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to confirm all expected assemblies and assets are present.