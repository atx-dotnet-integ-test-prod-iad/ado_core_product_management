# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this is consistent across all projects in the solution, particularly `AdoCore.csproj` and any projects that depend on it.

### 2. Restore Dependencies
Run a full NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm there are no latent issues:

```bash
dotnet clean
dotnet build
```

Address any warnings that surface, particularly those related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test
```

Review test output carefully. A passing build does not guarantee correct runtime behavior, especially after a framework migration.

### 5. Check for Platform-Specific Code
Search the codebase for APIs that were available in .NET Framework but have limited or no support in cross-platform .NET, such as:

- `System.Web` namespaces
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage beyond what is supported
- COM interop or P/Invoke calls targeting Windows-only libraries

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify these if needed.

### 6. Review Configuration Files
Confirm that any `app.config` or `web.config` files have been migrated to the appropriate `appsettings.json` format or that the configuration system in use is compatible with `Microsoft.Extensions.Configuration`.

### 7. Validate Runtime Behavior
Run the application manually and exercise the primary workflows to confirm behavior matches the original. Pay particular attention to:

- File path handling (directory separators differ across platforms)
- Culture and encoding defaults, which may differ between .NET Framework and modern .NET
- Reflection-based code, which may behave differently under the new runtime

### 8. Test on Target Platforms
If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that a build alone will not catch.

```bash
dotnet run
```

Execute this on each target platform and compare output and behavior.