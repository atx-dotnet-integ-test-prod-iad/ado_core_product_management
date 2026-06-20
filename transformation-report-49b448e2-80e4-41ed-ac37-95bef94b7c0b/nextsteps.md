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
Perform a clean build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review test output carefully, paying attention to any tests that were previously passing and are now failing.

### 5. Check for Windows-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any remaining Windows-specific API calls that may compile successfully but fail at runtime on Linux or macOS:

```bash
dotnet add package Microsoft.Windows.Compatibility
```

Alternatively, run a static analysis pass using:

```bash
dotnet build /p:EnableWindowsTargeting=true
```

Review any `CA1416` platform compatibility warnings that surface.

### 6. Run the Application on Each Target Platform
Execute the application on each platform you intend to support (Windows, Linux, macOS) and verify core functionality behaves as expected. Pay particular attention to:

- File path handling (use `Path.Combine` rather than hardcoded separators)
- Environment variable access
- Any registry or Windows-specific configuration that may need to be replaced with a cross-platform alternative such as `appsettings.json` or environment variables

### 7. Review Output Artifacts
Publish the application and inspect the output:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Confirm the published output contains the expected assemblies and that no legacy `.config` files are being relied upon at runtime.

### 8. Review Removed or Changed APIs
Cross-reference the [.NET API compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) for any APIs that were available in .NET Framework but have been removed or have changed behavior in modern .NET. Common areas to check include:

- `System.Web` usage (not available in .NET Core/.NET 5+)
- `AppDomain` usage
- Binary serialization (`BinaryFormatter` is obsolete and disabled by default)
- `ConfigurationManager` (requires the `System.Configuration.ConfigurationManager` NuGet package)