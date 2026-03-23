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

Run the following command from the solution root to ensure all dependencies are correctly restored:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or incompatible packages.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release
```

Review the test results and investigate any failures, as they may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Windows-Specific API Usage

Even without build errors, some APIs may compile successfully but fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer or review the code manually for usage of:

- `Microsoft.Win32` registry APIs
- `System.Windows.Forms` or `System.Drawing` (GDI+)
- COM interop
- P/Invoke calls targeting Windows-specific native libraries

Run the following to surface platform compatibility warnings:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

## 6. Run the Application

Execute the application directly to validate runtime behavior:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

If the project is a library rather than an executable, write a small integration test or console harness to exercise its public API.

## 7. Test on Target Platforms

If cross-platform support is a goal, run the application or tests on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that static analysis may not catch.

## 8. Review `app.config` or `web.config` Migrations

.NET no longer uses `app.config` or `web.config` in the same way as .NET Framework. Confirm that any configuration values have been migrated to `appsettings.json` and that `Microsoft.Extensions.Configuration` is being used where appropriate.

## 9. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) for your deployment target. Review the contents of the `publish` output folder before deploying.