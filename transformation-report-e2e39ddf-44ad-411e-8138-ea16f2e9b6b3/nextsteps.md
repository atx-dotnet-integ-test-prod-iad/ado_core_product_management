# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm there are no hidden warnings or errors:

```bash
dotnet build --configuration Release
```

Review any warnings in the output, particularly `CS0618` (obsolete members) or platform-compatibility warnings (`CA1416`), as these may indicate areas that require attention at runtime even if the build succeeds.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Pay close attention to any tests that exercise platform-specific functionality such as file I/O paths, registry access, or Windows-specific APIs, as these are common sources of cross-platform issues.

### 5. Check for Platform-Specific API Usage
Use the .NET Compatibility Analyzer or review the build output for `CA1416` warnings. These indicate calls to APIs that are only supported on specific operating systems. If the project is intended to run on non-Windows platforms, these areas will need to be addressed with either guards or cross-platform alternatives:

```csharp
if (OperatingSystem.IsWindows())
{
    // Windows-specific code
}
```

### 6. Review Configuration and App Settings
If the project previously used `System.Configuration` (e.g., `App.config` or `Web.config`), confirm that configuration has been migrated to `Microsoft.Extensions.Configuration` using `appsettings.json` or environment variables, as `System.Configuration` has limited support in cross-platform .NET.

### 7. Validate Runtime Behavior
Run the application directly and exercise its primary workflows:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Confirm that database connections, file paths, and any external integrations behave as expected on the target operating system.

### 8. Publish the Application
Once validation is complete, publish a self-contained or framework-dependent release build:

**Framework-dependent:**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all expected assets are present before deploying.