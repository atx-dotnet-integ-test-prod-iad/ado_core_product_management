# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or obsolete APIs, as these can indicate areas that may cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated to determine whether they reflect a regression introduced by the migration or a pre-existing issue.

## 4. Verify Target Framework

Open each `.csproj` file and confirm that the `<TargetFramework>` element references the intended cross-platform .NET version (e.g., `net8.0`). Ensure no projects are still targeting `net48` or another Windows-only framework unintentionally.

## 5. Check for Windows-Specific APIs

Even without build errors, runtime failures can occur if the code uses Windows-specific APIs that are not available on Linux or macOS. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Review any diagnostics produced and replace or conditionally compile platform-specific code as needed.

## 6. Review Configuration and File Paths

Inspect any hardcoded file paths or configuration values in `appsettings.json`, environment-specific config files, or code. Replace Windows-style paths (e.g., backslashes) with `Path.Combine` or forward-slash equivalents to ensure cross-platform compatibility.

## 7. Test on Target Platforms

Run the application on each platform you intend to support (Windows, Linux, macOS) to identify any runtime behavior differences that would not surface during a build.

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application for your target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier for your deployment target (e.g., `win-x64`, `osx-x64`). Review the publish output directory to confirm all required files are present.

## 9. Review Removed or Changed APIs

Consult the [.NET breaking changes documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/breaking-changes) relevant to the .NET version you have migrated to. Cross-reference any APIs used in the project that may have changed behavior or been removed.