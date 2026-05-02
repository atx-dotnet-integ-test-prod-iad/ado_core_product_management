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

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check both `Debug` and `Release` configurations to rule out configuration-specific issues.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failed or skipped tests that may indicate behavioral differences introduced by the migration.

### 5. Check for Windows-Specific APIs
Use the .NET Upgrade Assistant Analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any remaining Windows-specific API calls that may compile successfully but fail at runtime on Linux or macOS:

```bash
dotnet add package Microsoft.Windows.Compatibility
```

Alternatively, run the solution on a non-Windows machine or within a non-Windows environment to surface any platform-specific runtime exceptions.

### 6. Review Removed References
Confirm that any references that were removed during transformation — such as references to `System.Web`, `System.Drawing`, or COM interop assemblies — have been replaced with appropriate cross-platform equivalents where necessary.

### 7. Validate Application Output
Run the application directly and exercise its primary workflows to confirm functional correctness:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Compare the output or behavior against the known behavior of the original legacy project.

### 8. Publish the Application
Once validation is complete, produce a published output to confirm the deployment artifact is generated correctly:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to confirm all required assemblies, configuration files, and assets are present.