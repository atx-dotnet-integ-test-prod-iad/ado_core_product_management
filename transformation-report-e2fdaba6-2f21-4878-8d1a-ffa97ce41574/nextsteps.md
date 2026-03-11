# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other outdated monikers unless intentionally kept for multi-targeting.

### 2. Restore and Build from the Command Line
Run the following commands from the solution root to confirm a clean restore and build outside of any IDE:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns.

### 3. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding.

### 4. Check for Removed or Changed APIs
Even without build errors, some APIs behave differently on cross-platform .NET. Review any code that touches the following areas, as these are common sources of runtime issues after migration:

- `System.Windows.Forms` or `System.Drawing` (not supported on Linux/macOS without additional packages)
- `System.Configuration.ConfigurationManager` (requires the `System.Configuration.ConfigurationManager` NuGet package)
- Registry access (`Microsoft.Win32.Registry`)
- COM interop or P/Invoke calls targeting Windows-specific libraries
- `AppDomain` usage, as some members are no longer supported

### 5. Audit NuGet Package Compatibility
Run the following command to check for any packages that may not be compatible with the new target framework:

```bash
dotnet list package --outdated
dotnet list package --deprecated
```

Update or replace any packages flagged as deprecated or incompatible.

### 6. Run on All Target Platforms
If cross-platform support is a goal, execute the application and its tests on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime exceptions that would not appear at compile time.

### 7. Review Output Artifacts
Confirm the build output is placed in the expected location and that all required assets (configuration files, static resources, etc.) are being copied correctly:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to ensure all necessary files are present.

### 8. Validate Application Behavior
Perform a functional walkthrough of the application's primary workflows to confirm that behavior matches the pre-migration baseline. Pay particular attention to:

- File I/O paths (use `Path.Combine` and avoid hardcoded backslashes)
- Culture and encoding assumptions
- Thread and async behavior differences between .NET Framework and modern .NET