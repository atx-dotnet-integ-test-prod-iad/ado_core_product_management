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
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Run a full solution build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that may indicate compatibility issues even if they do not block the build.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and modern .NET (e.g., changes in globalization, threading, or reflection behavior).

### 5. Check for Removed or Changed APIs
Even with a clean build, some APIs behave differently on cross-platform .NET. Review the code for usage of the following common problem areas:

- `System.Drawing` — requires the `System.Drawing.Common` NuGet package and has platform restrictions on non-Windows systems.
- `System.Web` — not available on cross-platform .NET; any remaining references should be replaced with `Microsoft.AspNetCore` equivalents.
- Registry access (`Microsoft.Win32.Registry`) — only functional on Windows.
- `AppDomain.CreateDomain` — not supported on .NET Core and later.
- `BinaryFormatter` — disabled by default in .NET 5+ and removed in .NET 9.

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to surface any remaining compatibility concerns.

### 6. Test on Target Platforms
If cross-platform support (Linux, macOS) is a goal, run the application and its tests on those operating systems to catch any platform-specific runtime issues that would not appear during a Windows build.

### 7. Review Configuration and App Settings
Confirm that any configuration files (`app.config`, `web.config`) have been migrated to the appropriate modern equivalents such as `appsettings.json` and that the application reads them correctly at runtime using `Microsoft.Extensions.Configuration`.

### 8. Validate Runtime Output
Run the application end-to-end and compare its behavior against the original .NET Framework version to confirm functional parity. Pay particular attention to:

- File path handling (path separator differences between Windows and Linux/macOS).
- Culture and encoding defaults, which changed between .NET Framework and .NET Core+.
- Any use of `Thread.CurrentThread.CurrentCulture` or similar locale-sensitive operations.