# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless that is intentional for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm there are no issues that may have been masked:

```bash
dotnet build --configuration Release
```

Review all warnings in the output, as some warnings may indicate runtime issues even when the build succeeds.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify functional correctness after the transformation:

```bash
dotnet test --configuration Release
```

Review any failing tests and determine whether they are caused by behavioral differences between .NET Framework and cross-platform .NET, such as changes in globalization, reflection, or file path handling.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any remaining calls to Windows-only APIs (e.g., registry access, `System.Drawing`, WCF server-side components). Run the following if the analyzer is installed:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

Address any `CA1416` platform compatibility warnings that appear.

### 6. Verify Runtime Behavior
Run the application on each intended target platform (Windows, Linux, macOS) to confirm there are no runtime exceptions caused by platform-specific assumptions in the original code, such as:

- Hard-coded Windows-style file paths using backslashes
- `Environment.SpecialFolder` paths that differ across platforms
- Case-sensitive file system access on Linux

### 7. Review Configuration Files
Confirm that any `App.config` or `Web.config` files have been migrated to `appsettings.json` or the appropriate .NET configuration model, and that the application reads configuration correctly at runtime.

### 8. Publish the Application
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier for your deployment target. Review the publish output directory to confirm all required assets are present.