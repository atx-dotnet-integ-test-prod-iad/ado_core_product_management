# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

### 2. Restore NuGet Packages
Run the following command from the solution root to ensure all dependencies are restored cleanly:

```bash
dotnet restore
```

Verify there are no warnings about deprecated or missing packages in the output.

### 3. Build the Solution
Perform a full build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Review the output for any warnings that could indicate compatibility issues even if the build succeeds.

### 4. Run Existing Tests
If the solution contains test projects, execute the test suite to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 5. Check for Windows-Specific APIs
Even when a project builds successfully, it may reference APIs that only function correctly on Windows. Use the .NET Compatibility Analyzer or review the code manually for usages such as:

- `Microsoft.Win32` registry access
- `System.Windows.Forms` or `System.Drawing` (GDI+)
- COM interop or P/Invoke calls targeting Windows system libraries

If any are found, evaluate whether platform guards (`RuntimeInformation.IsOSPlatform`) or cross-platform alternatives are needed.

### 6. Review NuGet Package Compatibility
Check that all referenced NuGet packages support the target framework. Packages targeting only `net4x` may have been included via compatibility shims. Visit [nuget.org](https://www.nuget.org) to confirm each package has a native build for your target framework.

### 7. Validate Application Behavior
Run the application manually and exercise its primary workflows to confirm runtime behavior matches expectations from the legacy version. Pay particular attention to:

- File path handling (directory separators differ on Linux/macOS)
- Configuration file loading (e.g., `app.config` vs `appsettings.json`)
- Serialization and encoding behavior differences between runtimes

### 8. Publish the Application
Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assets and dependencies are present before deploying to the target environment.