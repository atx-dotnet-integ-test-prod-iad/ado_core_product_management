# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other outdated monikers unless intentionally targeting multiple frameworks.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if they do not produce build errors.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding.

### 4. Check NuGet Package Compatibility
Review all NuGet dependencies in each `.csproj` file. Confirm that every package version listed on [nuget.org](https://www.nuget.org) supports the target framework. Pay particular attention to packages that previously targeted `net45`–`net48` and may have compatibility shims rather than native cross-platform support.

### 5. Audit Platform-Specific APIs
Use the .NET Upgrade Assistant compatibility analyzer or the built-in Roslyn analyzers to identify any calls to Windows-specific APIs (e.g., registry access, `System.Drawing`, COM interop). Run the following if the analyzer package is referenced:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

Replace or conditionally compile any platform-specific code that is not appropriate for the target platforms.

### 6. Validate Runtime Behavior on Target Platforms
If cross-platform support (Linux, macOS) is a goal, run the application on each intended operating system and exercise the primary code paths to surface any runtime-only issues such as file path casing sensitivity or missing native libraries.

### 7. Review `AdoCore.csproj` Specifically
Since `AdoCore.csproj` is listed as the most independent project in the solution, confirm the following within it:

- All project references resolve correctly.
- Any ADO.NET or data-access related packages (e.g., `System.Data`, database drivers) are compatible with the target framework.
- Connection string handling and any platform-dependent data provider registrations have been updated for cross-platform use.

### 8. Check Output Artifacts
After a successful Release build, inspect the output directory (`bin/Release/<tfm>/`) to confirm:

- The expected assemblies and dependencies are present.
- No unnecessary platform-specific native binaries are bundled unintentionally.

### 9. Publish a Test Build
Run a local publish to verify the published output is complete and self-consistent:

```bash
dotnet publish --configuration Release --output ./publish-output
```

Test the published output by running the entry-point executable directly from the `publish-output` directory.