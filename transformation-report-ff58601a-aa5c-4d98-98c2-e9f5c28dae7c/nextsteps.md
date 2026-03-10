# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional for multi-targeting.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not block the build.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in globalization, file path handling, or reflection behavior).

### 4. Check for Platform-Specific API Usage
Use the .NET Compatibility Analyzer or review the code manually for any APIs that were available in .NET Framework but are absent or behave differently in cross-platform .NET. Common areas to check include:

- `System.Web` references (not available outside of ASP.NET Core)
- Windows Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions (backslashes, drive letters)
- `AppDomain` usage
- Binary serialization (`BinaryFormatter`, which is obsolete and disabled by default)

### 5. Review NuGet Package Compatibility
Confirm that all NuGet dependencies support the target framework. Run:

```bash
dotnet list package --outdated
```

Replace any packages that do not support your target framework with their modern equivalents or alternatives.

### 6. Validate Runtime Behavior
Execute the application manually or through integration tests and verify:

- Configuration files are loaded correctly (e.g., migration from `App.config`/`Web.config` to `appsettings.json` if applicable)
- Logging behaves as expected
- Any file I/O operations use cross-platform path separators (`Path.Combine` rather than hardcoded separators)

### 7. Review Assembly and Namespace Changes
Some types were moved between assemblies or namespaces in cross-platform .NET. If the build succeeded but runtime exceptions occur, check for `TypeLoadException` or `MissingMethodException` and trace them back to API surface changes.

### 8. Publish the Application
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value for your target platform, for example `win-x64`, `linux-x64`, or `osx-x64`. Review the publish output directory to confirm all required assets are present.