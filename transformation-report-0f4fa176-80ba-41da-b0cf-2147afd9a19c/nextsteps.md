# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other outdated monikers unless intentionally targeting multiple frameworks.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

### 4. Check for Removed or Changed APIs
Use the .NET Upgrade Assistant compatibility analyzer or review the [.NET API differences](https://docs.microsoft.com/en-us/dotnet/core/compatibility/) to confirm that no APIs used in the codebase have been removed or had breaking changes introduced in the target framework version.

You can also run:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

This will surface additional compatibility and code quality diagnostics.

### 5. Review NuGet Package Versions
Open each `.csproj` file and verify that all `<PackageReference>` entries reference versions compatible with the target framework. Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update packages where appropriate, and re-run the build and tests after doing so.

### 6. Validate Platform-Specific Code
Search the codebase for any usage of Windows-specific APIs (e.g., `System.Windows.Forms`, `Microsoft.Win32`, COM interop, or P/Invoke calls targeting Windows DLLs). If found, either:
- Guard them with runtime checks using `OperatingSystem.IsWindows()`, or
- Replace them with cross-platform alternatives.

### 7. Run on Target Platforms
Execute the application on each platform you intend to support (e.g., Windows, Linux, macOS) to catch any runtime behavior differences that do not surface at compile time:

```bash
dotnet run --configuration Release
```

### 8. Publish a Release Build
Once validation is complete, produce a self-contained or framework-dependent publish to confirm the output is as expected:

```bash
# Framework-dependent
dotnet publish --configuration Release --output ./publish

# Self-contained (example for Linux x64)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish-linux
```

Verify the output directory contains all expected files and that the application runs correctly from the published output.