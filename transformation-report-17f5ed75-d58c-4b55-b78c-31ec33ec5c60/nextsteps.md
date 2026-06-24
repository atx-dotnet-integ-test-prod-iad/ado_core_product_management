# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version you intend to support.

## 2. Restore Dependencies

Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts.

## 3. Build the Solution

Perform a clean build to confirm there are no issues introduced by the environment:

```bash
dotnet build --configuration Release
```

Review the output and confirm there are zero errors and review any warnings.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review test results and address any failing tests before proceeding.

## 5. Validate Platform-Specific Code

Search the codebase for any APIs that were previously Windows-only and may not behave as expected on other platforms. Common areas to check include:

- `Registry` access (`Microsoft.Win32.Registry`)
- `System.Drawing` (GDI+ based operations)
- Windows Event Log usage
- COM interop calls
- File path separators (use `Path.Combine` and `Path.DirectorySeparatorChar`)

Use the .NET Compatibility Analyzer to assist with this:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

## 6. Check for Removed or Changed APIs

Review any use of APIs that have been removed or altered in modern .NET. The [.NET Upgrade Assistant](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) and the [.NET API compatibility tooling](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/api-analyzer) can help identify these issues.

## 7. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (Windows, Linux, macOS) to surface any runtime behavior differences that do not appear at compile time.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate RID for your target platform (e.g., `win-x64`, `osx-x64`). Review the output directory to confirm all required files are present.

## 9. Review Output Artifacts

Inspect the published output to confirm:

- The correct .NET runtime or runtime stubs are included based on your self-contained or framework-dependent choice.
- Configuration files (e.g., `appsettings.json`) are present and correctly set for the target environment.
- No legacy `.config` files (e.g., `app.config`) are being relied upon in ways that are incompatible with modern .NET configuration patterns.