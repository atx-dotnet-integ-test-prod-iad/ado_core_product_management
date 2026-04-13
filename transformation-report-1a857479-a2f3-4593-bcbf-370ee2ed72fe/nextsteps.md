# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other .NET Framework moniker unless that is intentional for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm there are no warnings that could indicate runtime issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify behavioral correctness after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by migration-related changes or pre-existing issues.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any APIs that are Windows-only or otherwise platform-restricted. You can also enable the platform compatibility analyzer by adding the following to your `.csproj`:

```xml
<PropertyGroup>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <AnalysisMode>All</AnalysisMode>
</PropertyGroup>
```

Rebuild after enabling this and review any `CA1416` (platform compatibility) warnings.

### 6. Verify Runtime Behavior
Run the application on each target platform (Windows, Linux, macOS as applicable) to confirm there are no runtime exceptions caused by platform-specific assumptions in the original code, such as file path separators, registry access, or Windows-specific libraries.

```bash
dotnet run --configuration Release
```

### 7. Review Removed or Changed APIs
Check for any usage of APIs that were removed or had behavioral changes between .NET Framework and modern .NET. The [.NET Upgrade Assistant documentation](https://learn.microsoft.com/en-us/dotnet/core/porting/) and the [.NET API compatibility tool](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/api-analyzer) are useful references for this step.

### 8. Publish the Application
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed. Review the publish output directory to confirm all required assets are present.