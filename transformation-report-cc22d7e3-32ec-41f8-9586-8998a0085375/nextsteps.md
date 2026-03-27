# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional.

### 2. Restore Dependencies
Run a full NuGet restore from the solution root to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm there are no warnings that could indicate runtime issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify functional correctness after the transformation:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee correct runtime behavior.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any Windows-only API calls that may compile successfully but fail at runtime on Linux or macOS:

```bash
dotnet add package Microsoft.Windows.Compatibility
```

Alternatively, review the code manually for usages of APIs such as `System.Windows.Forms`, `Microsoft.Win32`, or `System.Drawing` that may have limited cross-platform support.

### 6. Run the Application on Target Platforms
Execute the application on each platform you intend to support (Windows, Linux, macOS) and verify behavior is consistent:

```bash
dotnet run --configuration Release
```

Pay particular attention to file path handling, environment variable access, and any platform-specific configuration loading.

### 7. Review Configuration Files
Check `appsettings.json`, `app.config`, or any other configuration files to ensure they do not contain Windows-specific paths, registry references, or connection strings that will not function cross-platform.

### 8. Publish a Self-Contained Build
Produce a self-contained publish output for your target runtime identifier (RID) to confirm the application packages correctly:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Repeat for each target platform as needed (e.g., `win-x64`, `osx-x64`).