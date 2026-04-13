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
Perform a clean build to confirm there are no issues that may have been masked:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or platform compatibility (e.g., `CA1416`).

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failed or skipped tests and investigate accordingly.

### 5. Check for Removed APIs
Use the .NET Compatibility Analyzer or review the output of:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

Pay attention to any `SYSLIB` or `CA` diagnostic codes that indicate use of obsolete or platform-specific APIs that may not behave identically on non-Windows platforms.

### 6. Verify Runtime Behavior
Run the application locally on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Confirm that database connections, file paths, and any OS-specific logic function correctly on each platform.

### 7. Publish a Self-Contained Output
Produce a published output to confirm the application packages correctly:

```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 -o ./publish
```

Adjust the `--runtime` flag to match your deployment target (e.g., `win-x64`, `osx-x64`, `linux-arm64`).

### 8. Review Configuration Files
Confirm that any `App.config` or `Web.config` files have been replaced or supplemented with `appsettings.json` and that configuration is being read using `Microsoft.Extensions.Configuration` where applicable.

### 9. Inspect Third-Party Package Compatibility
Cross-reference all NuGet dependencies against [nuget.org](https://www.nuget.org) to confirm each package has a version that targets `netstandard2.0` or the specific .NET version in use. Replace any packages that are Windows-only or .NET Framework-only with supported alternatives.