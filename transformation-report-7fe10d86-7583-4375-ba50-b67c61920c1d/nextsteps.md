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
Run a full NuGet restore from the solution root to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm the absence of errors is consistent:

```bash
dotnet build --configuration Release
```

Review any warnings in the output, as some warnings may indicate compatibility issues that do not prevent compilation but could cause runtime problems.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior:

```bash
dotnet test --configuration Release
```

Review test results carefully, paying attention to any tests that were previously passing under the legacy framework but now fail.

### 5. Check for Windows-Specific API Usage
Even if the build succeeds, the code may contain calls to Windows-specific APIs (e.g., the registry, `System.Windows.Forms`, COM interop, or P/Invoke calls targeting Windows DLLs). Use the .NET Compatibility Analyzer or review analyzer warnings in your IDE to identify any such usages:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

Address any `CA1416` (platform compatibility) warnings that surface.

### 6. Validate Runtime Behavior on Target Platforms
Run the application on each platform you intend to support (Linux, macOS, Windows) and confirm that core functionality behaves as expected. Pay particular attention to:

- File path handling (use `Path.Combine` rather than hardcoded separators)
- Line ending differences
- Case sensitivity on Linux file systems
- Environment variable and configuration file resolution

### 7. Review NuGet Package Compatibility
Check that all third-party NuGet packages in use have versions that support the target framework. Visit [nuget.org](https://www.nuget.org) for each package and confirm `.NET` or `.NET Standard` compatible versions are referenced. Replace any packages that only supported `.NET Framework` with their modern equivalents.

### 8. Review `app.config` / `web.config` Migrations
If the legacy project used `app.config` or `web.config`, confirm that configuration has been migrated to `appsettings.json` or another supported configuration provider, as `ConfigurationManager` behavior differs in cross-platform .NET.

### 9. Publish a Self-Contained Build
Produce a self-contained publish output for your primary target runtime to confirm the full publish pipeline works:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Repeat for any other target runtimes as needed (e.g., `win-x64`, `osx-x64`).