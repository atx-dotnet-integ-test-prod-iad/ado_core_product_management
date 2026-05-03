# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless that is intentional for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings flagged during this step, particularly those related to nullable reference types or obsolete API usage.

### 4. Run Existing Tests
If the solution contains test projects, execute the test suite to confirm existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests and determine whether they are failing due to behavioral differences between .NET Framework and cross-platform .NET, such as changes in globalization, file path handling, or reflection behavior.

### 5. Check for Platform-Specific API Usage
Use the .NET Compatibility Analyzer or review the code manually for APIs that are Windows-specific and may not behave correctly on Linux or macOS. Common areas to check include:

- `System.Drawing` (requires `libgdiplus` on non-Windows or replacement with a cross-platform library)
- Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) server-side APIs
- `System.Security.Cryptography` APIs that rely on Windows CAPI/CNG

Run the following to surface compatibility warnings:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

### 6. Validate Runtime Behavior
Run the application on the target platform(s) and exercise the primary workflows manually or through integration tests. Pay particular attention to:

- File path separators (`\` vs `/`)
- Case sensitivity of the file system on Linux
- Environment variable differences across operating systems
- Culture and encoding differences

### 7. Review Removed or Changed APIs
Cross-reference the project's usage of any APIs listed in the [.NET breaking changes documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/breaking-changes) relevant to the version you are targeting. Address any identified incompatibilities in the source code.

### 8. Publish the Application
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value, for example `win-x64`, `linux-x64`, or `osx-x64`. Review the publish output directory to confirm all required assets are present before deployment.