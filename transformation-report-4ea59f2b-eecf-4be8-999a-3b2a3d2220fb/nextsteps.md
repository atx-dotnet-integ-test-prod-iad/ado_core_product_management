# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other .NET Framework moniker unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

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

### 4. Run Existing Tests
If the solution contains test projects, execute the test suite to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., changes in globalization, reflection, or threading behavior).

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any APIs that are Windows-specific and may not behave correctly on Linux or macOS:

```bash
dotnet add package Microsoft.Windows.Compatibility
```

Only add this package if Windows-specific APIs are required. Otherwise, replace those APIs with cross-platform alternatives.

### 6. Verify Runtime Behavior on Target Platforms
If the goal is cross-platform execution, run the application on each intended operating system (Windows, Linux, macOS) to confirm consistent behavior:

```bash
dotnet run --configuration Release
```

Pay particular attention to:
- File path separators (`/` vs `\`)
- Case-sensitive file systems (Linux)
- Environment variable differences
- Culture and encoding defaults

### 7. Review Output Artifacts
Confirm the build output is placed in the expected directory and that all necessary assets (configuration files, static resources, etc.) are copied correctly:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` folder to ensure all required files are present before deploying to the target environment.