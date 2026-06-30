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

Review the output for any warnings that may indicate compatibility issues, even if they do not cause build failures.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by API differences between .NET Framework and modern .NET.

### 4. Check for Removed or Changed APIs
Use the [.NET Upgrade Assistant](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the [Platform Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to identify any API usage that may compile successfully but behave differently at runtime on cross-platform .NET.

### 5. Review NuGet Package Compatibility
Open the `.csproj` files and review all `<PackageReference>` entries. For each package, confirm that the version referenced supports the target framework. You can verify this on [nuget.org](https://www.nuget.org) by checking the listed supported frameworks for each package version.

### 6. Test on Target Platforms
If cross-platform support is a goal, run the application and its tests on each intended operating system (e.g., Windows, Linux, macOS) to surface any platform-specific runtime issues:

```bash
dotnet run --configuration Release
```

Pay particular attention to:
- File path separators
- Registry access (not available on non-Windows)
- Windows-specific APIs such as `System.Drawing` or `Microsoft.Win32`

### 7. Publish the Application
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate Runtime Identifier (RID) for your deployment target. A full list of RIDs is available in the [.NET RID Catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).

### 8. Verify Published Output
Navigate to the publish output directory and confirm all expected assemblies, configuration files, and assets are present before deploying to the target environment.