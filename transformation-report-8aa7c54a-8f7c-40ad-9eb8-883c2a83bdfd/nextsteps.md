# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netstandard2.0`, or other legacy monikers unless intentionally kept for multi-targeting.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding further.

### 4. Check for Removed or Changed APIs
Use the .NET Upgrade Assistant compatibility analyzer or review the [.NET API compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) to identify any APIs that were available in the legacy framework but have been removed or changed in the target .NET version. Pay particular attention to:

- `System.Web` usages (not available in cross-platform .NET)
- Windows-only APIs (e.g., registry access, WCF server-side, Windows Forms if targeting non-Windows)
- Reflection APIs that have changed behavior

### 5. Review NuGet Package Versions
Open the `.csproj` files or a central `Directory.Packages.props` file and confirm all NuGet dependencies have versions compatible with the target framework. Run:

```bash
dotnet list package --outdated
```

Update packages that have newer compatible versions, and replace any packages that are no longer maintained with their recommended alternatives.

### 6. Validate Platform-Specific Behavior
If `AdoCore` or any dependent project uses platform-specific features (file paths, process management, networking), test explicitly on each target operating system (Windows, Linux, macOS) to confirm consistent behavior.

### 7. Review Runtime Configuration Files
Check for the presence and correctness of:

- `appsettings.json` / `appsettings.{Environment}.json`
- `runtimeconfig.json` or `runtimeconfig.template.json`
- Any `app.config` files that may have been carried over from the legacy project (these are not used the same way in cross-platform .NET)

### 8. Publish a Release Build
Once validation passes, produce a release publish to confirm the output is complete and runnable:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the contents of the `./publish` directory and run the output directly to confirm the application starts and behaves correctly.