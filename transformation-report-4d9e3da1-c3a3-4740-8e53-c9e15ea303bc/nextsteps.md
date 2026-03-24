# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other .NET Framework moniker unless a multi-targeting scenario is intentional.

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

Address any failing tests before proceeding further.

### 4. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any remaining calls to Windows-only APIs (e.g., `System.Drawing`, `Registry`, `Windows.Forms` internals). Run the analyzer with:

```bash
dotnet add package Microsoft.DotNet.Compatibility
```

Or use the built-in Roslyn analyzers by ensuring this is present in each `.csproj`:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

Rebuild and review the diagnostics output.

### 5. Verify NuGet Package Compatibility
Check that all NuGet dependencies have versions compatible with your target framework. Review the `packages.lock.json` or run:

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

Update any outdated or vulnerable packages, then rebuild and retest.

### 6. Validate Runtime Behavior
Execute the application manually or through integration tests on each target platform (Windows, Linux, macOS as applicable) to confirm there are no runtime exceptions caused by platform-specific behavior differences.

### 7. Review Configuration and App Settings
Confirm that any configuration files (e.g., `appsettings.json`, environment variables) are correctly structured for the .NET generic host or ASP.NET Core configuration system, replacing any legacy `App.config` or `Web.config` patterns where necessary.

## Deployment

### 1. Publish the Application
Use the `dotnet publish` command to produce deployment artifacts:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

### 2. Verify the Published Output
Inspect the `./publish` directory to confirm all expected assemblies, configuration files, and static assets are present.

### 3. Test the Published Output
Run the published output directly on the target machine or environment to confirm it starts and functions correctly outside of the development toolchain:

```bash
./publish/AdoCore
```

Or on Windows:

```bash
.\publish\AdoCore.exe
```