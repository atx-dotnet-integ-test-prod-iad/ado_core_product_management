# Next Steps

The solution appears to have transformed successfully — no build errors were reported across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless a multi-targeting scenario is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm there are no warnings that could indicate hidden compatibility issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility annotations (`[SupportedOSPlatform]`).

### 4. Run the Test Suite
If the solution contains test projects, execute all tests to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and modern .NET (e.g., changes in `HttpClient`, serialization, threading, or globalization).

### 5. Check for Windows-Specific API Usage
If cross-platform support is a goal, use the .NET Compatibility Analyzer to identify any Windows-only API calls:

```bash
dotnet build /p:PlatformTarget=AnyCPU
```

Look for `CA1416` analyzer warnings, which flag APIs that are not available on all platforms.

### 6. Review `AdoCore.csproj` Specifically
Since `AdoCore` is the most independent project in the solution (listed last), verify the following within it:

- Any ADO.NET-related dependencies (e.g., `System.Data`, database drivers) are compatible with the target framework.
- Connection string handling and database provider packages (e.g., `Microsoft.Data.SqlClient` instead of `System.Data.SqlClient`) are up to date.
- No references to legacy `System.Web` or COM interop components remain.

### 7. Validate Runtime Behavior
Run the application manually or through its entry point and exercise the core workflows, paying attention to:

- File path handling (use `Path.Combine` and avoid hardcoded backslashes).
- Configuration loading (migrate from `App.config`/`Web.config` to `appsettings.json` if not already done).
- Encoding and globalization behavior, which can differ between .NET Framework and modern .NET.

### 8. Review Output Artifacts
Confirm the build output directory contains the expected binaries and that no unintended `.config` or legacy files are being carried over:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` folder to ensure only the necessary files are present for deployment.