# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other .NET Framework moniker unless that is intentional for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm there are no issues beyond what was captured in the transformation output:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly `NU1701` warnings, which indicate a package was restored for a different framework and may not be fully compatible.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., changes in globalization, reflection, or threading behavior).

### 5. Check for Windows-Specific API Usage
Even without build errors, certain APIs that compiled successfully may throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code for usages of:
- `System.Windows.Forms` or `System.Web`
- `Microsoft.Win32` registry APIs
- P/Invoke calls targeting Windows-only native libraries

### 6. Run the Application
Execute the application directly to confirm it starts and operates correctly:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Test all primary code paths, paying particular attention to database access, file I/O, and any networking code, as these areas commonly surface cross-platform issues at runtime.

### 7. Review Output Artifacts
Confirm the build output is placed in the expected directory and that all required assets (configuration files, static resources, etc.) are present:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to verify the output is complete before proceeding to any deployment activity.