# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless that is intentional for multi-targeting.

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

### 4. Check for Removed or Changed APIs
Some .NET Framework APIs are not available or behave differently in cross-platform .NET. Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` compatibility tooling to identify any runtime-level API gaps that would not surface as build errors.

### 5. Review NuGet Package Versions
Open each `.csproj` and verify that all `<PackageReference>` entries reference package versions that support the target framework. You can check compatibility on [nuget.org](https://www.nuget.org/) or by running:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with cross-platform support.

### 6. Validate Platform-Specific Code
Search the codebase for any usage of Windows-specific APIs such as the registry, `System.Drawing`, COM interop, or `System.Windows.Forms`. These will not function on non-Windows platforms. Replace or conditionally compile them as needed using runtime checks:

```csharp
if (OperatingSystem.IsWindows())
{
    // Windows-specific logic
}
```

### 7. Test on Target Platforms
If cross-platform support is a goal, run the application on each intended operating system (Linux, macOS, Windows) to catch any platform-specific runtime failures that would not appear during a Windows-only build.

### 8. Publish the Application
Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate RID (e.g., `win-x64`, `osx-x64`) based on your deployment environment. Review the publish output directory to confirm all required files are present.