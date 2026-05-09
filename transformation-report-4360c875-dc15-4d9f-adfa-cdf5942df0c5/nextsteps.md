# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm there are no errors or warnings that were not surfaced previously:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify that existing behavior has been preserved after the transformation:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated to determine whether they indicate a regression introduced during the migration.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer or the following command to identify any APIs that are not supported on all target platforms:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to analyzer warnings with codes such as `CA1416`, which flag platform-specific API calls that may not work on Linux or macOS.

### 6. Verify Runtime Behavior
Run the application on each platform you intend to support (Windows, Linux, macOS) and confirm that core functionality behaves as expected. Pay attention to:

- File path handling (`Path.Combine` vs hardcoded separators)
- Case sensitivity in file system operations
- Environment variable usage that may differ across platforms

### 7. Review Configuration and Assembly References
Check that any remaining references to `System.Configuration`, `System.Web`, or other .NET Framework-specific assemblies have been replaced with their .NET equivalents or appropriate NuGet packages, such as `Microsoft.Extensions.Configuration`.

### 8. Publish the Application
Once validation is complete, publish the application for your target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed. Review the publish output directory to confirm all required files are present.