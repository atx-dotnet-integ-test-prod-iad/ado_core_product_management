# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation

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

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm there are no errors or warnings that may have been masked:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings (CA1416).

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify functional correctness after the transformation:

```bash
dotnet test --configuration Release
```

Review test output for any failures or skipped tests that may indicate platform-specific behavior that no longer applies.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer or the following CLI tool to scan for APIs that are not supported on all platforms:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review any code that uses namespaces such as `Microsoft.Win32`, `System.Windows.Forms`, or `System.Drawing` (non-`Common` variant), as these may require additional packages or refactoring to work cross-platform.

### 6. Verify Configuration and App Settings
If the project uses configuration files such as `App.config` or `Web.config`, confirm these have been migrated to `appsettings.json` or the appropriate .NET configuration model, as `System.Configuration.ConfigurationManager` has limited support and behavior differences on non-Windows platforms.

### 7. Test on Target Platforms
If cross-platform support is a goal, run and test the application on each intended operating system (Linux, macOS, Windows) to surface any runtime platform differences that static analysis would not catch:

```bash
dotnet run --configuration Release
```

### 8. Review Output Artifacts
Publish the project and inspect the output to confirm the correct runtime assets are included:

```bash
dotnet publish --configuration Release --output ./publish
```

If a self-contained deployment is needed, specify the runtime identifier:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```