# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-only TFM such as `net472` or `net48`, update it accordingly.

## 2. Restore NuGet Packages

Run the following command from the solution root to ensure all dependencies are properly restored:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or incompatible packages.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types or obsolete APIs, as these can indicate potential runtime issues.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review the test results carefully. Any failing tests should be investigated before proceeding.

## 5. Validate Platform-Specific Code

Search the codebase for any APIs that were previously Windows-only and may not behave identically on other platforms. Common areas to check include:

- `System.Windows.Forms` or `System.Drawing` usage
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions (e.g., backslashes, drive letters)
- P/Invoke calls to Windows DLLs
- `Environment.SpecialFolder` paths that differ across operating systems

Use the .NET Compatibility Analyzer or the `dotnet-compatibility` tool to assist:

```bash
dotnet tool install -g dotnet-compatibility
```

## 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (Linux, macOS, Windows) to surface any runtime issues that do not appear at compile time.

## 7. Review Configuration Files

Check that any configuration files (e.g., `appsettings.json`, connection strings, file paths) are updated to work in a cross-platform context. Avoid hardcoded Windows-style paths.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate RID for your target platform (e.g., `win-x64`, `osx-x64`). Review the output directory to confirm all necessary files are present.

## 9. Review Output Artifacts

Inspect the published output to ensure:

- No unintended Windows-specific binaries are included
- Configuration files are present and correctly populated
- The executable runs on the target platform without requiring additional dependencies beyond what is bundled