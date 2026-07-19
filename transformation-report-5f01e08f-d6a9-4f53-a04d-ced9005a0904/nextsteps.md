# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless a multi-targeting scenario is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete API usage, as these can indicate latent issues.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may point to behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in `System.Drawing`, `System.Security`, or culture-sensitive operations).

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any APIs that are Windows-only. If the project is intended to run on Linux or macOS, any `[SupportedOSPlatform("windows")]` warnings should be resolved:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

### 6. Verify Runtime Behavior
Run the application directly and exercise its primary code paths:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Pay particular attention to:
- File path handling (use `Path.Combine` rather than hardcoded separators)
- Database connectivity strings, especially if using SQL Server or OLE DB providers
- Any reflection-based code that may behave differently under the new runtime

### 7. Review NuGet Package Compatibility
Open the solution in Visual Studio or run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Replace any packages that have known cross-platform alternatives. For example:
- `System.Data.OleDb` is Windows-only; consider `Microsoft.Data.SqlClient` if applicable
- `Microsoft.VisualBasic` has limited cross-platform support

### 8. Deployment
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) for your deployment target. Review the contents of the `publish` output folder to confirm all required assets are present.