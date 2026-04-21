# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm the clean state holds outside of the transformation environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete APIs, as these can indicate areas of the code that may behave differently on cross-platform .NET.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures at this stage often point to behavioral differences between .NET Framework and cross-platform .NET (e.g., `System.Drawing`, `WCF`, `Remoting`, `AppDomain` usage).

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for APIs that exist in .NET but behave differently across operating systems:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to:
- File path handling (`Path.DirectorySeparatorChar`)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-only APIs guarded by `[SupportedOSPlatform("windows")]`

### 6. Test on Target Platforms
If cross-platform support (Linux, macOS) is a goal, run the built output on each target operating system to surface any runtime issues that static analysis may not catch.

### 7. Review `AdoCore.csproj` Specifically
Since `AdoCore` is the project referenced in this transformation, open its `.csproj` and confirm:
- All `<PackageReference>` entries have versions compatible with the target framework.
- Any ADO.NET-related packages (e.g., `System.Data`, database drivers) are the cross-platform compatible versions.
- No `<Reference>` elements point to legacy GAC assemblies or absolute Windows paths.

### 8. Smoke Test Core Functionality
Manually exercise the primary entry points or APIs exposed by `AdoCore` to confirm data access operations behave correctly at runtime, including connection handling, query execution, and exception propagation.