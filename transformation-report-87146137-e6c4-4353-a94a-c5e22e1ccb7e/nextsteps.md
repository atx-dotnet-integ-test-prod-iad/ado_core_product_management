# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other .NET Framework moniker unless that is intentional for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm there are no errors or warnings that were not captured previously:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review test output carefully, paying attention to any tests that were previously passing and are now failing or being skipped.

### 5. Check for Windows-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any remaining Windows-specific API calls (e.g., registry access, `System.Windows.Forms`, COM interop) that may compile successfully but fail at runtime on non-Windows platforms:

```bash
dotnet add package Microsoft.Windows.Compatibility
```

Alternatively, run the platform compatibility analyzer by building with:

```bash
dotnet build -p:EnableNETAnalyzers=true
```

Review any `CA1416` platform compatibility diagnostics that are emitted.

### 6. Verify Runtime Behavior
Run the application on each target platform (Windows, Linux, macOS as applicable) and exercise the primary code paths to confirm there are no runtime exceptions related to platform differences.

### 7. Review NuGet Package Versions
Check that all third-party NuGet packages in use have versions that support your target framework. Visit [nuget.org](https://www.nuget.org) for each package and confirm `.NET` or `.NET Standard` compatible versions are referenced.

### 8. Publish the Application
Once validation is complete, produce a release build artifact using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime, use:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the contents of the `./publish` directory and confirm the application starts correctly from that output folder.