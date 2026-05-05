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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding.

### 4. Check for Platform-Specific API Usage
Even without build errors, some APIs may have been silently replaced or may throw `PlatformNotSupportedException` at runtime. Review the code for usage of:

- `System.Windows.Forms` or `System.Web` (these require additional packages or are unavailable cross-platform)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions (e.g., hardcoded backslashes)
- `AppDomain` and remoting APIs

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package to identify these at development time.

### 5. Review NuGet Package Compatibility
Open the `.csproj` files and check each `<PackageReference>`. Confirm that all referenced NuGet packages have versions that support the target framework. You can verify this on [nuget.org](https://www.nuget.org) or by running:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with cross-platform support.

### 6. Validate Configuration Files
If the project previously used `app.config` or `web.config`, confirm that settings have been migrated to `appsettings.json` or the appropriate .NET configuration model. The legacy XML-based configuration system has limited support in modern .NET.

### 7. Smoke Test on Target Platforms
Run the application on each platform you intend to support (Windows, Linux, macOS) to catch any runtime-only platform issues:

```bash
dotnet run --configuration Release
```

If cross-platform execution is a hard requirement, test on a non-Windows environment explicitly.

### 8. Publish a Release Build
Once validation passes, produce a published output to confirm the deployment artifact is correct:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to ensure all required assets, dependencies, and configuration files are present.