# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other Windows-only framework monikers unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Resolve any warnings about deprecated or unlisted packages by updating them to their current equivalents.

### 3. Build the Solution
Perform a clean build to confirm there are no warnings that could indicate runtime issues:

```bash
dotnet build --configuration Release
```

Review any remaining warnings, particularly those related to nullable reference types, obsolete APIs, or platform compatibility analyzers (CA1416).

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify behavioral correctness after the transformation:

```bash
dotnet test --configuration Release
```

Review any failing tests and determine whether they indicate a regression introduced during migration or a pre-existing issue.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer or review the build output for `CA1416` warnings. These indicate calls to APIs that are only supported on Windows. If the goal is true cross-platform support, these usages will need to be replaced or guarded with runtime checks:

```csharp
if (OperatingSystem.IsWindows())
{
    // Windows-specific code
}
```

### 6. Verify Runtime Behavior on Target Platforms
Run the application on each intended target platform (Linux, macOS, Windows) to catch any platform-specific runtime issues that static analysis may not surface, such as file path casing sensitivity or platform-specific encoding defaults.

### 7. Review Configuration and File Paths
Confirm that any configuration files (e.g., `appsettings.json`) are included in the project output. Check `.csproj` files for correct `CopyToOutputDirectory` settings:

```xml
<ItemGroup>
  <Content Include="appsettings.json">
    <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
  </Content>
</ItemGroup>
```

Also verify that any hardcoded file paths use `Path.Combine` or `Path.DirectorySeparatorChar` rather than backslashes.

### 8. Publish a Release Build
Once validation is complete, produce a self-contained or framework-dependent publish to confirm the output is deployable:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to ensure all required assets and dependencies are present.