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

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm there are no warnings that could indicate runtime issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify existing behavior has been preserved:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failures that did not exist before the transformation should be investigated as potential regressions.

### 5. Check for Platform-Specific API Usage
Use the .NET Compatibility Analyzer to identify any APIs that are Windows-only or otherwise platform-restricted. These will appear as warnings with codes such as `CA1416`. Review each occurrence and determine whether a cross-platform alternative is needed or whether a platform guard is appropriate.

### 6. Review `app.config` / `web.config` Migrations
If the original project used `app.config` or `web.config`, confirm that configuration has been migrated to `appsettings.json` or another supported mechanism. Verify that configuration is being read correctly at runtime.

### 7. Validate Runtime Behavior
Run the application on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement. Pay particular attention to:

- File path separators
- Environment variable usage
- Registry access (Windows-only)
- Any P/Invoke or native interop calls

### 8. Inspect Output Artifacts
After a Release build, inspect the output directory to confirm the expected assemblies, runtime identifiers, and publish profiles are correct:

```bash
dotnet publish --configuration Release
```

Verify the published output contains all required files and that no extraneous legacy artifacts are included.