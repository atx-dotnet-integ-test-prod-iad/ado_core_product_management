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

Resolve any warnings about deprecated or unlisted packages by updating them to their current equivalents.

### 3. Build the Solution
Perform a clean build to confirm there are no warnings that may indicate hidden compatibility issues:

```bash
dotnet build --configuration Release
```

Review any remaining warnings, particularly those related to nullable reference types, platform compatibility (`CA1416`), or obsolete APIs.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger trx
```

Review the generated `.trx` results files for any failures or skipped tests that need attention.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer or the following CLI tool to identify any remaining platform-specific API calls that may fail on Linux or macOS:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to usage of `System.Windows.Forms`, `System.Drawing`, `Microsoft.Win32.Registry`, or P/Invoke calls targeting Windows-only libraries.

### 6. Validate Runtime Behavior
Run the application directly to confirm it starts and operates as expected:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Test all major code paths, particularly any database connections, file I/O, or network calls that may behave differently across operating systems (e.g., file path separators, case sensitivity).

### 7. Review `app.config` / `web.config` Migrations
If the original project used `app.config` or `web.config`, confirm that settings have been properly migrated to `appsettings.json` or environment variables, and that `Microsoft.Extensions.Configuration` is wired up correctly.

### 8. Verify Output Artifacts
Confirm the published output is correct by running:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to ensure all expected assemblies, configuration files, and static assets are present.