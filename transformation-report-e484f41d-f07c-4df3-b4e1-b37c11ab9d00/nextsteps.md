# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netstandard2.0`, or other legacy monikers unless intentionally retained.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved references.

### 3. Build the Solution
Perform a clean build to confirm there are no warnings that could indicate latent issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify behavioral correctness after the migration:

```bash
dotnet test --configuration Release
```

Review test output for any failures or skipped tests that may indicate platform-specific behavior that was not accounted for during transformation.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to scan for any APIs that are Windows-only or otherwise platform-restricted. Run the following if the analyzer is installed:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

Pay particular attention to any `CA1416` (platform compatibility) warnings.

### 6. Verify Runtime Behavior
Run the application on each target platform (Windows, Linux, macOS as applicable) to confirm runtime behavior is consistent:

```bash
dotnet run --configuration Release
```

Test all major application workflows manually or through integration tests.

### 7. Publish the Application
Once validation is complete, publish the application for the target runtime(s):

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed. Review the publish output directory to confirm all required assets are present.

### 8. Review NuGet Package Versions
Check that all third-party NuGet packages in use have versions compatible with the target .NET version. Cross-reference against [NuGet.org](https://www.nuget.org) or the package's official documentation if any runtime exceptions occur that were not present before migration.