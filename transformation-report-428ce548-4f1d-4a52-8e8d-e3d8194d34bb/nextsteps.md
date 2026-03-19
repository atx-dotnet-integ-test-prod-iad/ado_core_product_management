# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework is set to the intended cross-platform .NET version (e.g., `net6.0`, `net7.0`, or `net8.0`):

```xml
<TargetFramework>net8.0</TargetFramework>
```

If the value is still referencing a Windows-specific framework such as `net472` or `net48`, update it accordingly.

## 2. Restore NuGet Packages

Run the following command from the solution root to ensure all dependencies are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or incompatible packages. Replace any packages that do not support the target framework with their cross-platform equivalents.

## 3. Build the Solution

Perform a clean build to confirm there are no hidden compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review the build output for any warnings that may indicate compatibility concerns, even if they do not produce errors.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release
```

Review the test results carefully. Any failing tests should be investigated to determine whether they are caused by behavioral differences in the new runtime.

## 5. Check for Windows-Specific API Usage

Even without build errors, the code may reference APIs that are only functional on Windows. Use the .NET Compatibility Analyzer to surface these at build time by adding the following to `AdoCore.csproj`:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

Rebuild and review any new warnings prefixed with `CA1416` (platform compatibility).

## 6. Test on Target Platforms

Run the application on each platform you intend to support (Linux, macOS, Windows) to identify any runtime issues that static analysis may not catch:

```bash
dotnet run --configuration Release
```

Pay particular attention to file path handling, line endings, environment variable access, and any registry or COM interop usage.

## 7. Review Configuration and Runtime Behavior

- Confirm that any configuration files (e.g., `appsettings.json`) are correctly read at runtime on all target platforms.
- Verify that connection strings, file paths, and other environment-specific values are not hardcoded with Windows-style formatting.

## 8. Publish the Application

Once validation is complete, publish the application for the desired target:

**Framework-dependent (requires .NET runtime on target machine):**
```bash
dotnet publish -c Release -f net8.0
```

**Self-contained (includes runtime, no dependency on installed .NET):**
```bash
dotnet publish -c Release -f net8.0 --self-contained true -r linux-x64
```

Replace `linux-x64` with the appropriate runtime identifier for your target platform (e.g., `win-x64`, `osx-x64`, `osx-arm64`).

## 9. Verify Published Output

Navigate to the publish output directory and confirm the expected binaries and configuration files are present before deploying to the target environment.