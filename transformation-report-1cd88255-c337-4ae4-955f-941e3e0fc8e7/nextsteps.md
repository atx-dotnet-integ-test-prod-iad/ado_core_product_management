# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `net472`, or any other legacy .NET Framework moniker unless that is intentional for multi-targeting.

### 2. Restore and Build Locally
Run the following commands from the root of the solution to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding.

### 4. Check for Platform-Specific API Usage
Even with a successful build, some APIs that compiled under .NET Framework may throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Review the code for usage of:

- `System.Windows.Forms` or `System.Web`
- Registry access (`Microsoft.Win32.Registry`)
- COM interop
- Windows-specific file path assumptions (e.g., backslash separators)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package to identify these areas if needed.

### 5. Audit NuGet Package Compatibility
Verify that all NuGet dependencies support the target framework. Run:

```bash
dotnet list package --outdated
```

Replace any packages that do not have a compatible version with supported alternatives. Check [NuGet.org](https://www.nuget.org) for cross-platform compatible versions.

### 6. Validate Configuration Files
If the project previously relied on `app.config` or `web.config`, confirm that configuration has been migrated to `appsettings.json` or environment variables where appropriate, as `System.Configuration.ConfigurationManager` behavior differs in .NET.

### 7. Smoke Test on Target Platforms
Run the application on each platform you intend to support (Windows, Linux, macOS) and verify core functionality. Pay particular attention to:

- File I/O operations
- Network calls
- Any external process invocations

### 8. Publish the Application
Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate RID, for example `win-x64`, `linux-x64`, or `osx-x64`. Review the output in the `publish` folder before deploying to the target environment.