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
Perform a full build to confirm there are no warnings that could indicate runtime issues:

```bash
dotnet build --configuration Release
```

Review any remaining warnings, particularly those related to nullable reference types, obsolete APIs, or platform compatibility analyzers (CA1416).

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify functional correctness after the migration:

```bash
dotnet test --configuration Release --logger trx
```

Review the test results output and address any failing tests before proceeding.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer output from the build step to identify any calls to Windows-only APIs. These will appear as `CA1416` warnings. If the application must remain cross-platform, replace or conditionally compile those APIs using:

```csharp
if (OperatingSystem.IsWindows())
{
    // Windows-specific code
}
```

### 6. Verify Runtime Behavior
Run the application directly to confirm it behaves as expected on the target platform:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Test all major code paths, particularly any that involve file I/O, networking, or database access, as these areas are most commonly affected by cross-platform migrations.

### 7. Review Configuration Files
Check that any configuration files (e.g., `appsettings.json`, connection strings) have been updated to reflect the new .NET hosting model if the project previously used `App.config` or `Web.config`. The modern equivalent uses `Microsoft.Extensions.Configuration`.

### 8. Publish a Test Build
Produce a self-contained or framework-dependent publish output and verify it runs correctly on the target OS:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with your intended runtime identifier (e.g., `win-x64`, `osx-x64`) as appropriate.