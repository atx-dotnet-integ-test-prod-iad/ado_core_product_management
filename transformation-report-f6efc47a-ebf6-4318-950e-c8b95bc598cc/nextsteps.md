# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element targets the intended cross-platform .NET version, for example:

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
Perform a clean build to confirm there are no errors or warnings that were not caught previously:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings (CA1416).

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify that existing behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether the failures are due to the migration or pre-existing issues.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer to identify any remaining calls to Windows-only APIs. These will appear as analyzer warnings with code `CA1416`. Run the build with analysis enabled:

```bash
dotnet build --configuration Release /p:EnableNETAnalyzers=true
```

For any flagged APIs, either add a platform guard or replace the API with a cross-platform alternative.

### 6. Verify Runtime Behavior on Target Platforms
Run the application on each platform you intend to support (Linux, macOS, Windows) to confirm there are no platform-specific runtime exceptions. Pay particular attention to:

- File path separators (`/` vs `\`)
- Case sensitivity in file system operations
- Registry or Windows-specific configuration access
- `System.Drawing` or other packages that may require native dependencies on Linux

### 7. Review NuGet Package Compatibility
Check that all third-party NuGet packages in use have versions compatible with the target .NET framework. The following command can help identify outdated packages:

```bash
dotnet list package --outdated
```

Update packages where a newer version provides better cross-platform support.

### 8. Publish a Test Build
Produce a self-contained or framework-dependent publish output and verify the artifacts run correctly on the target platform:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier for your target environment (`win-x64`, `osx-x64`, `osx-arm64`, etc.).