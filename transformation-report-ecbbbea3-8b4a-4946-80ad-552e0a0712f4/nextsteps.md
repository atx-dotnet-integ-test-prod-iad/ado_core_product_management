# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation

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
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address the underlying causes before proceeding.

### 4. Check for Removed or Changed APIs
Some .NET Framework APIs are not available or behave differently in cross-platform .NET. Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` compatibility tooling to surface any runtime-level API issues that do not manifest as build errors:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <solution>.sln
```

### 5. Review NuGet Package Versions
Open each `.csproj` and verify that all NuGet package references are pointing to versions that support the target framework. Outdated packages may build successfully but cause runtime failures. You can check for outdated packages with:

```bash
dotnet list package --outdated
```

Update packages incrementally, testing after each change.

### 6. Validate Platform-Specific Code
Search the codebase for any usage of Windows-specific APIs such as:
- `System.Windows.Forms`
- `Microsoft.Win32.Registry`
- `System.Drawing` (GDI+)
- P/Invoke calls targeting Windows-only native libraries

If any are found and cross-platform support is required, these will need to be replaced with cross-platform alternatives or conditionally compiled using runtime checks:

```csharp
if (OperatingSystem.IsWindows())
{
    // Windows-specific logic
}
```

### 7. Test on Target Platforms
If the goal is cross-platform support, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues:

```bash
dotnet run --configuration Release
```

### 8. Publish the Application
Once validation is complete, publish the application for the target runtime(s):

```bash
# Framework-dependent publish
dotnet publish --configuration Release --output ./publish

# Self-contained publish for a specific runtime
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish/linux-x64
```

Review the output directory to confirm all required assets are present before deploying to the target environment.