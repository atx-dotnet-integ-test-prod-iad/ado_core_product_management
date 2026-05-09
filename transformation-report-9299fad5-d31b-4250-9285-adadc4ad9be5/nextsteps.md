# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Run a full solution build to confirm the no-error state is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Review the output for any warnings that may indicate compatibility concerns even if they do not block the build.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in globalization, file path handling, or reflection behavior).

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any APIs that are present but throw `PlatformNotSupportedException` at runtime on non-Windows platforms:

```bash
dotnet add package Microsoft.DotNet.ApiCompat
```

Pay particular attention to areas such as:
- `System.Drawing` (requires additional native dependencies on Linux/macOS)
- Windows Registry access (`Microsoft.Win32.Registry`)
- Windows-specific security or identity APIs

### 6. Run the Application
Execute the application directly to observe runtime behavior:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Test all major code paths, particularly any database access, file I/O, or network communication logic.

### 7. Verify NuGet Package Compatibility
Review the `packages.lock.json` or the restored package graph to confirm that all third-party dependencies have builds targeting .NET Standard 2.0 or later, or directly target the chosen .NET version. Packages that only ship `net4x` targets may still resolve but could behave unexpectedly.

### 8. Review Removed or Changed APIs
Consult the official .NET breaking changes documentation relevant to your migration path:

- [Breaking changes in .NET 5+](https://learn.microsoft.com/en-us/dotnet/core/compatibility/breaking-changes)

Cross-reference any areas of the codebase that interact with serialization, threading, networking, or security, as these areas have notable differences from .NET Framework.

### 9. Publish a Self-Contained Build
Once runtime validation is complete, produce a publish output to confirm the deployment artifact is correct:

```bash
dotnet publish --configuration Release --self-contained false --output ./publish
```

Verify the contents of the `./publish` directory match expectations for your deployment environment.