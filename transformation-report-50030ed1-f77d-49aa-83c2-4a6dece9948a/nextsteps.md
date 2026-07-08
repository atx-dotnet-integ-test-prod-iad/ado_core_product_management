# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional for multi-targeting.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if they do not block compilation.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and modern .NET (e.g., changes in globalization, threading, or reflection behavior).

### 4. Check for Removed or Changed APIs
Even with a clean build, some APIs behave differently on cross-platform .NET. Review the following areas manually:

- **`System.Configuration`**: `ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package on modern .NET.
- **`System.Drawing`**: Requires the `System.Drawing.Common` package and has platform restrictions on non-Windows systems.
- **WCF / Remoting**: These are not fully supported on cross-platform .NET. Verify any networking or service communication code.
- **Registry access**: `Microsoft.Win32.Registry` is Windows-only.
- **`AppDomain`**: Some members are no longer supported and will throw `PlatformNotSupportedException` at runtime.

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package to surface these issues automatically.

### 5. Validate NuGet Package Compatibility
Open the `.csproj` files and review all `<PackageReference>` entries. For each package, confirm:

- The version used supports your target framework.
- The package is not a `.NET Framework`-only package (check [nuget.org](https://nuget.org) for supported frameworks).

Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

### 6. Test on Target Platforms
If cross-platform support (Linux, macOS) is a goal, run the build and tests on those operating systems to surface any platform-specific runtime failures that would not appear on Windows.

### 7. Review Output Artifacts
Confirm the compiled output is placed in the expected location and that all referenced assets (configuration files, embedded resources, etc.) are included:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to ensure all required files are present.

### 8. Smoke Test the Application
Run the published application manually and exercise its primary functionality to confirm end-to-end behavior is correct before wider distribution.