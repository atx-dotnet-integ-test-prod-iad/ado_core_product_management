# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

### 2. Restore NuGet Packages
Run the following command from the solution root to ensure all dependencies resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts.

### 3. Build the Solution
Perform a full build to confirm there are no errors in the restored state:

```bash
dotnet build --configuration Release
```

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between the legacy .NET Framework APIs and the new cross-platform .NET runtime.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any APIs that are present at compile time but may throw `PlatformNotSupportedException` at runtime on non-Windows platforms:

```bash
dotnet add package Microsoft.Windows.Compatibility
```

Only add this package if Windows-specific APIs are genuinely required. Otherwise, replace those APIs with cross-platform equivalents.

### 6. Review `App.config` / `Web.config` Migrations
If the original project used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or the appropriate `Microsoft.Extensions.Configuration` provider, as these XML configuration files are not fully supported in cross-platform .NET.

### 7. Validate Output Artifacts
After a successful Release build, inspect the output directory (`bin/Release/net8.0/`) and confirm:
- The expected assemblies are present.
- No unnecessary legacy references (e.g., `System.Web`) appear in the dependency list.

### 8. Smoke Test the Application
Run the application directly using the .NET CLI to confirm it starts and operates correctly:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Observe startup logs and confirm no runtime exceptions occur during initialization.

### 9. Publish the Application
Once validation is complete, publish a self-contained or framework-dependent deployment as appropriate for your target environment:

**Framework-dependent:**
```bash
dotnet publish ./AdoCore/AdoCore.csproj --configuration Release --output ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish ./AdoCore/AdoCore.csproj --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory before deploying to the target machine.