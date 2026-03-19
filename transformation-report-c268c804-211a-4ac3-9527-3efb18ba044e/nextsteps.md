# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless a multi-targeting scenario is intentional.

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

### 4. Check for Removed or Changed APIs
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.ApiCompat` tooling to identify any APIs that were available in .NET Framework but have changed behavior or are absent in cross-platform .NET:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <solution>.sln
```

Review the generated report and address any compatibility findings.

### 5. Review NuGet Package Versions
Open each `.csproj` file and inspect `<PackageReference>` entries. Confirm that:
- All packages target .NET Standard 2.0+ or .NET 6/7/8 directly.
- No packages are pinned to versions that only supported .NET Framework.
- There are no duplicate or conflicting package versions across projects.

Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

### 6. Validate Platform-Specific Code
Search the codebase for any usage of Windows-specific APIs such as the registry, `System.Windows.Forms`, `System.Drawing` (GDI+), COM interop, or `System.Web`. These will compile on non-Windows targets only if the appropriate compatibility packages are referenced or the code is guarded with runtime checks:

```csharp
if (OperatingSystem.IsWindows())
{
    // Windows-specific logic
}
```

### 7. Test on Target Platforms
If cross-platform support (Linux, macOS) is a goal, run the application on each target operating system to surface any platform-specific runtime exceptions that would not appear during a Windows build.

```bash
dotnet run --configuration Release
```

### 8. Publish a Self-Contained Output
Produce a release publish to confirm the output is complete and runnable:

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 -o ./publish/win-x64
dotnet publish --configuration Release --self-contained true --runtime linux-x64 -o ./publish/linux-x64
```

Adjust the runtime identifiers (`-r`) to match your intended deployment targets. Verify the output directories contain all expected files and that the application starts correctly from the published output.