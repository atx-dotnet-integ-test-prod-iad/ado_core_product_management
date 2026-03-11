# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Resolve any warnings about deprecated or unlisted packages by updating them to their current equivalents.

### 3. Build the Solution
Perform a clean build to confirm there are no warnings that could indicate hidden compatibility issues:

```bash
dotnet build --configuration Release
```

Review any remaining warnings, particularly those related to nullable reference types, platform compatibility (`CA1416`), or obsolete API usage.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failed or skipped tests and investigate the root cause of each.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` analyzer to identify any remaining Windows-only API calls (e.g., registry access, `System.Drawing` on non-Windows, COM interop) that may compile successfully but fail at runtime on Linux or macOS.

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <solution>.sln
```

### 6. Validate Runtime Behavior
Run the application on each target platform (Windows, Linux, macOS) to confirm there are no platform-specific runtime failures:

```bash
dotnet run --project <StartupProject>.csproj --configuration Release
```

Pay particular attention to file path separators, environment variable access, and any configuration file loading logic.

### 7. Review `App.config` / `Web.config` Migrations
If the original project used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or another supported configuration provider, as `ConfigurationManager` behavior differs in cross-platform .NET.

### 8. Publish a Self-Contained Build
Produce a self-contained publish output and verify the application runs without requiring a separately installed .NET runtime:

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 -o ./publish/win-x64
dotnet publish --configuration Release --self-contained true --runtime linux-x64 -o ./publish/linux-x64
```

Test the resulting output directories on their respective platforms.