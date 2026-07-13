# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other legacy/end-of-life monikers unless intentional.

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

Address any failing tests before proceeding further.

### 4. Check NuGet Package Compatibility
Review all NuGet dependencies in each `.csproj` file. Confirm that every package supports the target framework. You can use the following command to identify outdated packages:

```bash
dotnet list package --outdated
```

Replace any packages that do not support the target framework with compatible alternatives or official .NET equivalents.

### 5. Review Removed or Changed APIs
Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any API usage that may compile successfully but behave differently at runtime on non-Windows platforms.

Pay particular attention to:
- `System.Drawing` (requires `System.Drawing.Common` and has platform restrictions)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific interop or P/Invoke calls

### 6. Test on Target Platforms
If cross-platform support is a goal, run the application and its tests on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime failures.

```bash
dotnet run --configuration Release
```

### 7. Publish the Application
Once validation is complete, produce a release build artifact using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime, use:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the contents of the `./publish` directory and confirm the application starts correctly from that output folder.