# Next Steps

The solution appears to have transformed successfully — no build errors were reported across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other outdated monikers unless intentionally targeting multiple frameworks.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved references.

### 3. Build the Solution
Perform a clean build to confirm there are no residual issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete APIs, as these can indicate future compatibility issues.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 5. Check for Windows-Specific API Usage
Even without build errors, certain APIs may compile successfully but fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code manually for usage of APIs such as:
- `System.Windows.Forms`
- `Microsoft.Win32` registry access
- `System.Drawing` (GDI+)
- P/Invoke calls targeting Windows-specific native libraries

### 6. Run the Application
Execute the application directly to confirm it starts and operates as expected:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Test the primary workflows of the application and compare output against the legacy version where possible.

### 7. Review NuGet Package Versions
Check that all third-party NuGet packages in use have versions that support your target framework. Visit [nuget.org](https://www.nuget.org) to confirm compatibility if any packages were carried over from the legacy project without version changes.

### 8. Publish the Application
Once validation is complete, publish a self-contained or framework-dependent build:

**Framework-dependent:**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all expected assets are present before deploying.