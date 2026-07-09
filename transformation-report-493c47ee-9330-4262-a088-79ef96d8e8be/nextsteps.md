# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other Windows-only framework monikers unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm the absence of errors is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that may indicate compatibility issues even if they do not block the build.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review test results carefully, paying attention to any tests that were previously passing but now fail, as these may indicate behavioral differences between .NET Framework and cross-platform .NET.

### 5. Check for Windows-Specific API Usage
Even without build errors, some APIs may compile successfully but fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer or review the code manually for usage of:

- `Microsoft.Win32` registry APIs
- Windows-specific interop (`DllImport` targeting Windows-only DLLs)
- `System.Windows.Forms` or `System.Drawing` (GDI+) without the appropriate compatibility packages
- `AppDomain` features that are no-ops or restricted in .NET Core and later

Run the following to surface platform compatibility warnings:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

### 6. Validate Configuration Files
Check that any `app.config` or `web.config` files have been migrated to the appropriate `appsettings.json` or environment-based configuration if the project type warrants it. The old XML-based configuration system has limited support in cross-platform .NET.

### 7. Test on Target Platforms
If cross-platform support is a goal, run and test the application on each intended operating system (Linux, macOS, Windows) to surface any runtime platform-specific issues that static analysis may not catch.

### 8. Publish the Application
Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value for your target platform, for example `win-x64`, `linux-x64`, or `osx-x64`. Review the publish output directory to confirm all required assets are present before deploying.