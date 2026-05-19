# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net48`, `netcoreapp`, or other legacy monikers unless intentionally targeting multiple frameworks.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved references.

### 3. Build the Solution
Perform a full build to confirm the clean state holds outside of the transformation environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly `CS0618` (obsolete API usage) or platform compatibility warnings (`CA1416`), as these may indicate APIs that do not behave consistently across platforms.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failed or skipped tests that may point to platform-specific issues.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer or the following CLI tool to scan for APIs that may not be supported on Linux or macOS:

```bash
dotnet tool install -g dotnet-apicompat
```

Pay particular attention to usages of `System.Windows.Forms`, `System.Drawing`, `Microsoft.Win32`, or P/Invoke calls, as these may require conditional compilation guards or replacement libraries.

### 6. Review `app.config` / `web.config` Migrations
If any configuration was previously held in `app.config` or `web.config`, confirm it has been migrated to `appsettings.json` or the `Microsoft.Extensions.Configuration` model, and that the application reads configuration correctly at runtime.

### 7. Validate Runtime Behavior on Target Platforms
Run the application on each intended target operating system (Windows, Linux, macOS as applicable) to surface any runtime-only platform incompatibilities that static analysis would not catch.

### 8. Publish the Application
Once validation is complete, produce a published output using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime, use:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the contents of the `./publish` directory and confirm the application starts correctly from that output folder before distributing.