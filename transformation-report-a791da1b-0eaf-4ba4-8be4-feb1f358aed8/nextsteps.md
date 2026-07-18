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

Review the output for any warnings about deprecated or unlisted packages and consider updating them.

### 3. Build the Solution
Perform a full build to confirm there are no issues beyond what was reported:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify behavioral correctness has been preserved:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated to determine whether they indicate a regression introduced during transformation or a pre-existing issue.

### 5. Review Platform-Specific Code
Search the codebase for any APIs that were previously Windows-specific, such as those in `System.Windows.Forms`, `Microsoft.Win32`, or `System.Drawing`. These may compile successfully but throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Use the [Platform Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to assist with this.

### 6. Verify Runtime Behavior
Run the application on each target platform (Windows, Linux, macOS as applicable) and exercise the primary workflows to confirm runtime behavior matches expectations from the legacy version.

### 7. Review `app.config` / `web.config` Migrations
If the legacy project used `app.config` or `web.config`, confirm that configuration has been properly migrated to `appsettings.json` or another supported .NET configuration mechanism. Verify that all configuration values are being read correctly at runtime.

### 8. Check for Removed or Changed APIs
Review any use of APIs that were removed or significantly changed between .NET Framework and modern .NET. The [.NET Upgrade Assistant](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) and the [.NET API compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) are useful references for this step.

### 9. Publish the Application
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value, for example `win-x64`, `linux-x64`, or `osx-x64`. Review the publish output directory to confirm all expected files are present before deploying.