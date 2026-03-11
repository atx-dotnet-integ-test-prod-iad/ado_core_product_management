# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other legacy/EOL targets unless intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages, missing versions, or compatibility issues.

### 3. Build the Solution
Perform a clean build to confirm there are no errors or warnings that may have been suppressed:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

### 4. Run the Test Suite
If the solution contains test projects, execute all tests to verify functional correctness after the transformation:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee behavioral correctness, so all existing tests should pass before proceeding.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to scan for any APIs that may compile successfully but fail at runtime on non-Windows platforms. Pay particular attention to:

- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific UI frameworks (e.g., `System.Windows.Forms`, `System.Drawing`)
- COM interop or P/Invoke calls targeting Windows-only native libraries

### 6. Run the Application
Execute the application directly to confirm runtime behavior:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Test all major code paths, particularly any database access, file I/O, or network operations that may behave differently across operating systems.

### 7. Review NuGet Package Compatibility
Check that all referenced NuGet packages support the target framework. Packages that have not been updated for modern .NET may require replacement with supported alternatives. The following command can help identify outdated packages:

```bash
dotnet list package --outdated
```

### 8. Validate on Target Platforms
If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a Windows-only build and test pass.