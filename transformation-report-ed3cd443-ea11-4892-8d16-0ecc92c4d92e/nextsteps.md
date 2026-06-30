# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build context:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated to determine whether they reflect a regression introduced by the migration or a pre-existing issue.

## 4. Verify Target Framework

Open each `.csproj` file and confirm that the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other Windows-only framework monikers unless that is intentional.

## 5. Check for Windows-Specific API Usage

Even without build errors, runtime failures can occur if the code references Windows-specific APIs that are not available on Linux or macOS. Use the .NET Compatibility Analyzer or review the code manually for usages such as:

- `Microsoft.Win32` registry APIs
- `System.Windows.Forms` or `System.Drawing` (without the `EnableWindowsFormsHighDpiAutoResizingPolicy` compatibility shim)
- P/Invoke calls to Windows DLLs

Run the following to surface platform compatibility warnings:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

## 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to catch any platform-specific runtime behavior that static analysis may not detect.

## 7. Review Output Artifacts

After a successful Release build, inspect the output directory (typically `bin/Release/net8.0/`) to confirm that all expected assemblies, configuration files, and dependencies are present.

## 8. Publish the Application

When validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` flag and `--self-contained` option based on whether you are deploying a framework-dependent or self-contained application.