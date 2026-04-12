# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other unintended frameworks.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they are not hard errors.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 4. Check for Windows-Specific API Usage
Even without build errors, certain APIs that compiled successfully may throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code for usages of:
- `System.Windows.Forms` or `System.Web`
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific P/Invoke calls
- `System.Security.Permissions` types that behave differently on .NET 5+

### 5. Review NuGet Package Compatibility
Confirm all NuGet dependencies support the target framework. Run:

```bash
dotnet list package --outdated
```

Replace any packages that do not have a compatible version with supported alternatives. Pay particular attention to packages that previously targeted `net45` or `net48` only.

### 6. Validate Configuration Files
If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or the appropriate .NET configuration model. The legacy XML-based configuration system has limited support in modern .NET.

### 7. Test on Target Platforms
If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to catch any platform-specific runtime issues that static analysis may not surface.

## Deployment

### 1. Publish the Application
Use the `dotnet publish` command to produce deployment artifacts:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that bundles the .NET runtime:

```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed.

### 2. Verify Published Output
Navigate to the output directory and confirm all expected binaries, configuration files, and assets are present before deploying to the target environment.

### 3. Confirm Runtime Installation on Target
If deploying a framework-dependent application (not self-contained), ensure the correct .NET runtime version is installed on the target machine:

```bash
dotnet --list-runtimes
```