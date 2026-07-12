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
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm the error-free state is consistent:

```bash
dotnet build --configuration Release
```

Review any warnings in the output, as some warnings may indicate compatibility issues that do not prevent compilation but could cause runtime problems.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior:

```bash
dotnet test --configuration Release
```

Review test results carefully. A successful build does not guarantee correct runtime behavior, especially after a framework migration.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any APIs that were available in .NET Framework but are absent or behave differently in cross-platform .NET:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to:
- `System.Windows.Forms` or `System.Web` references, which are not fully cross-platform
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions

### 6. Run the Application
Execute the application directly and exercise its primary workflows to confirm functional correctness:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

### 7. Review NuGet Package Versions
Check that all NuGet dependencies are up to date and have stable releases for the target framework. You can list outdated packages with:

```bash
dotnet list package --outdated
```

Update packages where appropriate, then re-run the build and tests.

### 8. Validate Output Artifacts
Publish the project to confirm the output is complete and self-contained if required:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to ensure all expected assemblies, configuration files, and assets are present.