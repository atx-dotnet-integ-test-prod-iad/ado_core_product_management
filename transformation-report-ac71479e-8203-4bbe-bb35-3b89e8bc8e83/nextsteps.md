# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm there are no errors or warnings that were not surfaced previously:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify that existing behavior has been preserved after the transformation:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer or the following command to identify any APIs that are Windows-specific and may not behave correctly on Linux or macOS:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to warnings with codes such as `CA1416` (platform compatibility).

### 6. Review Configuration and App Settings
Confirm that any configuration files (e.g., `appsettings.json`, environment variables) have been correctly migrated from the legacy `App.config` or `Web.config` format. The `System.Configuration.ConfigurationManager` NuGet package may be required if legacy configuration access patterns are still in use.

### 7. Verify Runtime Behavior
Run the application locally on the target platform and exercise the primary workflows to confirm that runtime behavior matches expectations from the legacy version. Pay attention to:

- File path separators (`/` vs `\`)
- Case sensitivity on Linux file systems
- Any platform-specific registry or COM interop calls that may no longer function

### 8. Publish the Application
Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier (e.g., `win-x64`, `osx-x64`) as needed. Review the publish output directory to confirm all required assets are present.