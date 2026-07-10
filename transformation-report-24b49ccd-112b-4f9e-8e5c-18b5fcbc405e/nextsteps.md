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
Perform a full build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that may indicate compatibility issues even if they do not block the build.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences introduced by the framework migration.

### 5. Check for Windows-Specific API Usage
Even if the project builds, some APIs are Windows-only and will fail at runtime on other platforms. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the build output for `CA1416` platform compatibility warnings.

### 6. Review `app.config` / `web.config` Usage
Cross-platform .NET does not use `app.config` or `web.config` in the same way as .NET Framework. Confirm that any configuration has been migrated to `appsettings.json` or environment-based configuration where applicable.

### 7. Validate Runtime Behavior on Target Platforms
Run the application on each platform you intend to support (Linux, macOS, Windows) and confirm expected behavior. Pay particular attention to:

- File path separators (`/` vs `\`)
- Case sensitivity in file system operations
- Registry access (not available on non-Windows platforms)
- Windows-specific interop or COM dependencies

### 8. Review NuGet Package Compatibility
Check that all referenced NuGet packages have versions that support the target framework. The following command can help identify outdated packages:

```bash
dotnet list package --outdated
```

Update packages where newer versions provide better cross-platform support.

### 9. Publish and Smoke Test
Publish the application for each target runtime and perform a basic smoke test:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Verify the published output runs correctly in each target environment.