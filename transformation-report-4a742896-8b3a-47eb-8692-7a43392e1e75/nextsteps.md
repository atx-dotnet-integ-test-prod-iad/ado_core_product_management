# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

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
Perform a clean build to confirm there are no issues that may have been masked:

```bash
dotnet build --configuration Release
```

Review all warnings in the output, as some warnings may indicate compatibility issues that do not prevent compilation but could cause runtime problems.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify functional correctness after the migration:

```bash
dotnet test --configuration Release
```

Review any failing tests and determine whether failures are caused by behavioral differences between .NET Framework and cross-platform .NET (e.g., changes in globalization, file path handling, or reflection behavior).

### 5. Check for Platform-Specific API Usage
Use the .NET Compatibility Analyzer or review the code manually for APIs that were available in .NET Framework but behave differently or are unavailable in cross-platform .NET. Common areas to check include:

- `System.Drawing` (requires the `System.Drawing.Common` package and may have OS restrictions)
- `System.Web` (not available in cross-platform .NET)
- Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) client/server usage
- `AppDomain` and remoting APIs

### 6. Validate Runtime Behavior
Run the application and exercise its primary workflows. Pay particular attention to:

- File system path separators (`\` vs `/`)
- Case sensitivity on Linux/macOS file systems
- Environment variable differences across operating systems
- Culture and encoding differences

### 7. Review NuGet Package Compatibility
Check that all referenced NuGet packages support the target framework. Packages that have not been updated in several years may only support .NET Framework. Use [NuGet.org](https://www.nuget.org) to verify framework compatibility for each dependency.

### 8. Publish the Application
Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime <runtime-identifier> --output ./publish
```

Replace `<runtime-identifier>` with the appropriate value for your target platform, such as `win-x64`, `linux-x64`, or `osx-x64`.

Verify the contents of the `./publish` directory and confirm the application starts and runs correctly from that location.