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
Perform a full build to confirm there are no warnings that could indicate runtime issues:

```bash
dotnet build --configuration Release
```

Review any warnings in the output, particularly those related to nullable reference types, obsolete APIs, or platform compatibility analyzers.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify behavioral correctness after the migration:

```bash
dotnet test --configuration Release
```

Review any failing tests and determine whether they are caused by migration-related changes or pre-existing issues.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer or review the build output for `CA1416` platform compatibility warnings. These warnings indicate calls to Windows-only APIs (such as the registry, certain `System.Drawing` types, or WinForms/WPF components) that will not function on Linux or macOS.

If cross-platform execution is required, replace or conditionally compile those APIs using:

```csharp
if (OperatingSystem.IsWindows())
{
    // Windows-specific code
}
```

### 6. Verify Configuration and File Paths
Check that any hardcoded file paths use `Path.Combine` or `Path.DirectorySeparatorChar` rather than backslashes, which are not valid path separators on Linux and macOS.

### 7. Run on Target Platforms
If the goal is cross-platform support, execute the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that static analysis may not catch:

```bash
dotnet run --configuration Release
```

### 8. Publish the Application
Once validation is complete, publish a self-contained or framework-dependent build for the target runtime:

```bash
# Framework-dependent
dotnet publish --configuration Release

# Self-contained for a specific runtime
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Review the output directory to confirm all required assets and dependencies are present.