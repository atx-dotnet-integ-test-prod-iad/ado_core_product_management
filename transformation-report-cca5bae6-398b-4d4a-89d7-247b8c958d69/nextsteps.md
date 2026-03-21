# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and test the migrated project before deploying it.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net48`, `netcoreapp`, or other legacy monikers unless there is a deliberate reason to multi-target.

## 2. Restore Dependencies

Run a full NuGet restore from the solution root to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

## 3. Build the Solution

Perform a clean build to confirm there are no warnings that could indicate runtime issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility analyzers.

## 4. Run the Existing Test Suite

Execute all unit and integration tests to verify behavioral correctness after the migration:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` results for any failing or skipped tests. Skipped tests in particular may indicate platform-specific code that was conditionally excluded during transformation.

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer or review the build output for `CA1416` warnings, which flag APIs that are only available on specific operating systems (e.g., Windows registry access, certain `System.Drawing` calls). Replace or guard these with appropriate cross-platform alternatives or runtime checks:

```csharp
if (OperatingSystem.IsWindows())
{
    // Windows-specific code
}
```

## 6. Validate Configuration and App Settings

If the project previously used `App.config` or `Web.config`, confirm that configuration has been migrated to `appsettings.json` and that `Microsoft.Extensions.Configuration` is being used to read those values at runtime.

## 7. Verify Runtime Behavior on Target Platforms

Run the application on each platform you intend to support (Windows, Linux, macOS) and confirm there are no runtime exceptions related to file paths, line endings, environment variables, or culture-sensitive operations.

```bash
dotnet run --configuration Release
```

Pay particular attention to:
- File path separators (`Path.Combine` vs hardcoded `/` or `\`)
- Case sensitivity in file system access on Linux
- Environment variable names and availability

## 8. Review Output Artifacts

Confirm the build output directory contains the expected assemblies and that no legacy `.exe` manifests or COM interop artifacts are being generated unexpectedly.

## 9. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent release:

```bash
# Framework-dependent
dotnet publish --configuration Release --output ./publish

# Self-contained for a specific runtime
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the contents of the `./publish` directory before deploying to the target environment.