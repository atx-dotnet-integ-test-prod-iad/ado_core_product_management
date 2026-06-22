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
Perform a clean build to confirm the absence of errors is consistent:

```bash
dotnet build --configuration Release
```

Review any warnings that surface during the build, as some may indicate compatibility issues that do not block compilation but could cause runtime problems.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior is intact after the transformation:

```bash
dotnet test --configuration Release
```

Pay attention to any tests that were previously passing on .NET Framework but now fail, as these may indicate behavioral differences between .NET Framework and modern .NET (e.g., changes in `System.Drawing`, `HttpClient`, serialization defaults, or reflection behavior).

### 5. Check for Removed or Changed APIs
Review the code for use of APIs that are present in .NET but behave differently from .NET Framework. Common areas to inspect include:

- `System.Web` — not available in modern .NET; replacements exist in `Microsoft.AspNetCore`.
- `BinaryFormatter` — disabled by default in .NET 5+.
- `AppDomain` — partially supported.
- `System.Drawing` — requires the `System.Drawing.Common` package and has platform restrictions on non-Windows systems.
- WCF server-side APIs — not available in modern .NET without third-party libraries such as CoreWCF.

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.ApiCompat` tooling to surface any such usages.

### 6. Test on Target Platforms
Since the goal is cross-platform support, run and test the application on each intended operating system (Windows, Linux, macOS) to catch platform-specific issues such as:

- File path separator assumptions (`\` vs `/`).
- Case-sensitive file systems on Linux.
- Platform-specific native library dependencies.

### 7. Review Configuration and Startup
If this is an application project (console, web, or desktop), verify that configuration sources (e.g., `appsettings.json`, environment variables) are wired up correctly under the modern .NET hosting model, replacing any legacy `App.config` or `Web.config` patterns where applicable.

### 8. Publish the Application
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` identifier and `--self-contained` flag to match your deployment requirements. Review the output directory to confirm all expected assets are present.