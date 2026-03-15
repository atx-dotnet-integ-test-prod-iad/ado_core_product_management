# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other unintended frameworks.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if they do not produce build errors.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding further.

### 4. Check NuGet Package Compatibility
Review all NuGet dependencies in each `.csproj` file. Confirm that every package has a version compatible with the target framework. You can use the following command to check for outdated packages:

```bash
dotnet list package --outdated
```

Replace any packages that do not support the target framework with their supported equivalents or alternatives.

### 5. Review Removed Windows-Specific APIs
Search the codebase for any APIs that are Windows-specific and may have been silently retained. Common areas to check include:

- `System.Windows.Forms` or `System.Drawing` (requires explicit package reference on non-Windows)
- Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) client or server usage
- `System.Security.Permissions` attributes

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify platform-specific calls.

### 6. Test on Target Platforms
If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime exceptions that would not appear during a build.

```bash
dotnet run --configuration Release
```

### 7. Publish a Release Build
Once validation is complete, produce a published output to confirm the deployment artifact is correct:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to ensure all required files and dependencies are present.

### 8. Verify Application Behavior
Perform functional testing against the published output to confirm the application behaves identically to the original legacy version. Pay particular attention to:

- Configuration file loading (e.g., `app.config` vs `appsettings.json`)
- File path handling (case sensitivity on Linux)
- Any serialization or reflection-based logic that may behave differently across frameworks