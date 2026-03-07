# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other Windows-only framework unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Resolve any warnings about deprecated or unlisted packages by updating them to their current equivalents.

### 3. Build the Solution
Perform a clean build to confirm there are no issues beyond what was reported:

```bash
dotnet build --configuration Release
```

Review the output for any warnings that may indicate compatibility concerns, even if they are not hard errors.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 5. Check for Windows-Specific API Usage
Even without build errors, certain APIs may have been silently replaced with stubs or may throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to check:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code manually for usages of:
- `System.Windows.Forms`
- `System.Drawing` (GDI+)
- `Microsoft.Win32` registry APIs
- COM interop

### 6. Run the Application
Execute the application directly and exercise its primary workflows to confirm runtime correctness:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

### 7. Test on Target Platforms
If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a build.

### 8. Review Output Artifacts
Confirm the output binaries are produced in the expected location and are of the expected type (e.g., executable vs. library):

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to verify all required files and dependencies are present.