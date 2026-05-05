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
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Resolve any warnings about deprecated or unlisted packages by updating them to their current equivalents.

### 3. Build the Solution
Perform a full build to confirm there are no warnings that could indicate hidden compatibility issues:

```bash
dotnet build --configuration Release
```

Review any warnings, particularly those related to nullable reference types, obsolete APIs, or platform compatibility analyzers (CA1416).

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger trx
```

Review the output for any failed or skipped tests and investigate the cause of each.

### 5. Check for Platform-Specific Code
Search the codebase for APIs that are Windows-specific and may compile successfully but fail at runtime on Linux or macOS. Common areas to check include:

- `Microsoft.Win32` registry access
- `System.Windows.Forms` or `System.Drawing` usage
- P/Invoke calls to Windows DLLs
- `Environment.SpecialFolder` paths that behave differently across platforms

Use the .NET Compatibility Analyzer output during the build step above to identify these locations.

### 6. Run the Application
Execute the application directly to validate runtime behavior:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Test all major code paths, particularly any that involve database access, file I/O, or network communication, as these areas are most likely to surface cross-platform differences at runtime.

### 7. Review NuGet Package Versions
Check that all referenced NuGet packages support the target framework. You can inspect this with:

```bash
dotnet list package --outdated
```

Update packages where newer versions provide better cross-platform support or address known issues.

### 8. Publish and Verify the Output
Produce a self-contained or framework-dependent publish output and verify it runs correctly on the intended target platform:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Adjust the `--runtime` identifier to match your deployment target (e.g., `win-x64`, `osx-x64`, `linux-arm64`).