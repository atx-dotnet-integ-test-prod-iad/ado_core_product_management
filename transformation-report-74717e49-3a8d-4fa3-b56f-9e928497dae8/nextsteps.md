# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netstandard2.0`, or other legacy monikers unless intentionally kept for compatibility.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved references.

### 3. Build the Solution
Perform a full build to confirm no errors or warnings are introduced at compile time:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings (CA1416).

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify existing behavior has been preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they indicate a regression introduced during migration or a test that requires updating for the new runtime.

### 5. Check for Windows-Specific APIs
Use the .NET Compatibility Analyzer to identify any remaining platform-specific API calls that may compile successfully but fail at runtime on non-Windows platforms:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to diagnostics prefixed with `CA1416` (platform compatibility).

### 6. Review Removed or Changed APIs
Cross-reference the project's use of any APIs that are known to be removed or behave differently in modern .NET. The official Microsoft documentation provides a [breaking changes reference](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) organized by .NET version that can assist with this review.

### 7. Manual Smoke Testing
Run the application manually and exercise its primary workflows to catch any runtime issues that static analysis and unit tests may not cover. Pay attention to:

- File I/O paths, which may behave differently across operating systems.
- Configuration file loading (e.g., `app.config` vs `appsettings.json`).
- Any reflection-based or dynamic code paths.

### 8. Verify Output Artifacts
Publish the application and inspect the output to confirm all required assets are present:

```bash
dotnet publish --configuration Release --output ./publish
```

Check that runtime dependencies, configuration files, and any native assets are included as expected.