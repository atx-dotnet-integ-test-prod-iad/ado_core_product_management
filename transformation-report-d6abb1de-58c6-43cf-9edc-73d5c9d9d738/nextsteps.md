# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other outdated monikers unless intentionally targeting multiple frameworks.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if they do not produce build errors.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding further.

### 4. Check NuGet Package Compatibility
Review all NuGet dependencies in each `.csproj` file. Confirm that every package supports the target framework. You can use the following command to identify outdated packages:

```bash
dotnet list package --outdated
```

Replace any packages that do not support the target framework with their cross-platform equivalents.

### 5. Review Removed Windows-Specific APIs
Search the codebase for APIs that are Windows-only and may have been silently retained. Common areas to check include:

- `System.Windows.Forms` or `System.Drawing` (GDI+)
- `Microsoft.Win32` registry access
- COM interop or P/Invoke calls targeting Windows system libraries
- `System.Security.Permissions` (partially removed in .NET Core and later)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package where applicable.

### 6. Run on All Target Platforms
If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to catch platform-specific runtime failures that do not surface during compilation.

```bash
dotnet run --configuration Release
```

### 7. Publish a Release Build
Once validation is complete, produce a published output to confirm the deployment artifact is generated correctly:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the contents of the `./publish` directory and confirm the application starts correctly from that output folder.

### 8. Review Application Configuration
Check that configuration files such as `appsettings.json` are present and that any references to `app.config` or `web.config` have been migrated to the appropriate .NET configuration system (`Microsoft.Extensions.Configuration`).