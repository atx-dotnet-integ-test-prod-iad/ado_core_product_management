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

Review the output for any warnings about deprecated or unlisted packages.

### 3. Build the Solution
Perform a full build to confirm there are no errors:

```bash
dotnet build --configuration Release
```

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any remaining Windows-only APIs that may compile successfully but fail at runtime on non-Windows platforms:

```bash
dotnet add package Microsoft.Windows.Compatibility
```

Alternatively, audit usages of namespaces such as `System.Windows`, `Microsoft.Win32`, or `System.Drawing` which may have platform restrictions.

### 6. Run the Application on Target Platforms
Execute the application on each platform you intend to support (Windows, Linux, macOS) and verify expected behavior:

```bash
dotnet run --configuration Release
```

Note any runtime exceptions that did not surface during the build.

### 7. Review NuGet Package Compatibility
Check that all referenced NuGet packages support the target framework. Packages that only target `net4x` or `netstandard1.x` may behave unexpectedly. Use the following to inspect resolved package versions:

```bash
dotnet list package
```

Consider updating outdated packages using:

```bash
dotnet outdated
```

### 8. Validate Output Artifacts
Confirm the build output in the `bin/Release/<TargetFramework>/` directory contains the expected assemblies and that no legacy `.config` files (such as `app.config` or `web.config`) are required but missing.

### 9. Publish a Test Build
Produce a self-contained or framework-dependent publish output and verify it runs correctly on the target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Adjust the `--runtime` identifier as appropriate for your deployment target.