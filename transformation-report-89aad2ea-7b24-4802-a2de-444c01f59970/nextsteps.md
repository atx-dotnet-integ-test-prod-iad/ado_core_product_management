# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

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
Perform a full build to confirm there are no warnings that may indicate runtime issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review test output carefully, particularly for any tests that were previously passing and now fail.

### 5. Check for Platform-Specific API Usage
Use the .NET Compatibility Analyzer or review the code manually for any APIs that are Windows-specific (e.g., `System.Windows.Forms`, `Microsoft.Win32`, registry access). These will compile but will throw `PlatformNotSupportedException` at runtime on non-Windows systems.

You can enable platform compatibility warnings by adding the following to your `.csproj`:

```xml
<PropertyGroup>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <AnalysisMode>All</AnalysisMode>
</PropertyGroup>
```

### 6. Run the Application
Execute the application on each target platform (Windows, Linux, macOS as applicable) to confirm runtime behavior is correct:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

### 7. Publish the Application
Once runtime validation is complete, publish a self-contained or framework-dependent build:

**Framework-dependent:**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish/linux-x64
```

Verify the output directory contains the expected binaries and that the application runs correctly from the published output.