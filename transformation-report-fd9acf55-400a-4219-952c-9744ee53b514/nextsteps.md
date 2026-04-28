# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless a multi-targeting scenario is intentional.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding.

### 4. Check NuGet Package Compatibility
Review all NuGet dependencies and confirm they have versions compatible with the target .NET version. You can use the following command to check for outdated packages:

```bash
dotnet list package --outdated
```

Replace any packages that target only `net4x` with their cross-platform equivalents where available.

### 5. Review Removed or Changed APIs
Use the [.NET Upgrade Assistant](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the [.NET API compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/api-compat-analyzer) to identify any usage of APIs that were removed or have behavioral differences in modern .NET. Run the analyzer as part of your build:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

### 6. Validate Runtime Behavior
Execute the application and walk through its primary workflows manually or via integration tests. Pay particular attention to:

- File I/O paths, as path separator behavior differs between Windows and Linux/macOS.
- Registry access, which is Windows-only and will throw on other platforms.
- `System.Drawing` usage, which requires the `System.Drawing.Common` package and has platform restrictions on non-Windows systems.
- Any use of `AppDomain`, `Remoting`, or `BinaryFormatter`, which are restricted or removed in modern .NET.

### 7. Confirm Platform Targets
If cross-platform execution is a goal, test the application on each intended target operating system:

```bash
dotnet run --configuration Release
```

Run this on Windows, Linux, and/or macOS as applicable to your deployment targets.

## Deployment

### 1. Publish a Self-Contained or Framework-Dependent Build
Choose a publish profile appropriate for your deployment environment.

**Framework-dependent (smaller output, requires .NET runtime on host):**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (includes runtime, no dependency on host):**
```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (`linux-x64`, `osx-x64`, etc.) as needed.

### 2. Verify Published Output
Navigate to the `./publish` directory and confirm all expected files are present, then run the published executable directly to validate it operates correctly outside the development environment.

### 3. Review Configuration Files
Ensure `appsettings.json` or equivalent configuration files are included in the published output and contain the correct values for the target environment. Legacy `app.config` or `web.config` files may need to be migrated to the modern configuration system if not already done.