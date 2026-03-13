# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

### 2. Restore Dependencies
Run the following command from the solution root to ensure all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm there are no errors:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failed or skipped tests and investigate accordingly.

### 5. Verify Platform-Specific Code
Search the codebase for any remaining usage of Windows-specific APIs that may not be available on other platforms. Common areas to check include:

- `Microsoft.Win32` namespace usage
- `Registry` access
- `System.Windows.Forms` or `System.Drawing` references
- P/Invoke calls targeting Windows-only native libraries

Use the .NET Upgrade Assistant compatibility analyzer or the `dotnet-compatibility` tool to assist:

```bash
dotnet tool install -g dotnet-compatibility
```

### 6. Check Runtime Behavior on Target Platforms
Run the application on each platform you intend to support (Linux, macOS, Windows) and verify that all core functionality behaves as expected. Pay particular attention to:

- File path handling (`Path.Combine` vs hardcoded separators)
- Line ending differences
- Case sensitivity in file system operations

### 7. Review NuGet Package Compatibility
Confirm that all referenced NuGet packages have versions compatible with the target framework. Packages that previously targeted `.NET Framework` may have newer versions with cross-platform support. Check [nuget.org](https://www.nuget.org) for updated versions where necessary.

### 8. Publish the Application
Once validation is complete, publish the application for the desired runtime(s):

```bash
# Framework-dependent publish
dotnet publish --configuration Release --output ./publish

# Self-contained publish for a specific runtime
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish/linux-x64
```

Verify the output in the publish directory runs correctly on the target machine.