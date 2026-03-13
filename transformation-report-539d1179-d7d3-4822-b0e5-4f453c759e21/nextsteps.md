# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that could not be resolved. If any packages are flagged, check [NuGet.org](https://www.nuget.org) for cross-platform compatible replacements.

## 3. Build the Solution

Perform a full build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Review the output for any warnings, even if there are no errors. Warnings related to platform compatibility (e.g., `CA1416`) may indicate code paths that only function on Windows.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests should be investigated before proceeding.

## 5. Check for Windows-Specific API Usage

Even without build errors, the code may contain APIs that are Windows-only. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Look for `CA1416` warnings, which indicate platform-specific API calls. These will compile successfully but will throw `PlatformNotSupportedException` at runtime on non-Windows systems.

## 6. Manual Runtime Testing

Run the application manually on each target platform (Windows, Linux, macOS as applicable) to catch any runtime issues that static analysis may not surface:

```bash
dotnet run --configuration Release
```

Pay particular attention to:
- File path separators (`\` vs `/`)
- Registry access (Windows-only)
- COM interop (Windows-only)
- `System.Drawing` usage (requires additional native dependencies on Linux/macOS)

## 7. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent build for your target platform:

**Framework-dependent:**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Verify the output in the `./publish` directory contains all expected files before deploying to the target environment.