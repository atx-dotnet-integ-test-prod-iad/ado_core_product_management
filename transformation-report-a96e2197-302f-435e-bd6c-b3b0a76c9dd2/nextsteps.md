# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

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
Perform a clean build to confirm there are no errors or warnings that may have been masked:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in globalization, file path handling, or reflection behavior).

### 5. Check for Windows-Specific API Usage
Even without build errors, certain APIs may compile successfully but fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these issues:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code for usages of:
- `Microsoft.Win32` registry APIs
- `System.Windows.Forms` or `System.Drawing` (unless the `EnableWindowsTargeting` flag is set)
- P/Invoke calls targeting Windows-only native libraries
- `System.Runtime.InteropServices.RuntimeInformation.IsOSPlatform` guards that may be missing

### 6. Validate Configuration and App Settings
If the project previously used `App.config` or `Web.config`, confirm that configuration has been migrated to `appsettings.json` or environment variables as appropriate for the application type.

### 7. Review Output Artifacts
After a successful Release build, inspect the output directory (`bin/Release/net8.0/`) and confirm:
- The expected assemblies are present
- No unnecessary `.config` transformation files remain
- Any self-contained or framework-dependent publish requirements are met

### 8. Publish the Application
Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime, use:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Replace `win-x64` with the appropriate Runtime Identifier (RID) for your target platform (e.g., `linux-x64`, `osx-x64`).

Refer to the [.NET RID Catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog) for a full list of supported runtime identifiers.