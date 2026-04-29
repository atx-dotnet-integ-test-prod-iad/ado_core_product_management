# Next Steps

The solution has no build errors following the transformation. Below are steps to validate, test, and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this matches the version of the .NET SDK you have installed. You can verify your installed SDKs by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not support the target framework or that have been resolved through compatibility shims.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface at this stage, particularly those related to obsolete APIs or platform-specific code paths.

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully. Failures may indicate behavioral differences between .NET Framework and cross-platform .NET, such as changes in globalization, file path handling, or reflection behavior.

## 5. Check for Windows-Specific API Usage

Even without build errors, the code may reference APIs that are Windows-only and will fail at runtime on other platforms. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code manually for usages of:
- `Microsoft.Win32` registry APIs
- `System.Windows.Forms` or `System.Drawing` (GDI+)
- P/Invoke calls to Windows DLLs
- `AppDomain` features that are no longer supported

## 6. Validate Configuration and File Paths

Cross-platform .NET is case-sensitive on Linux and macOS. Verify that:
- File paths use `Path.Combine` rather than hardcoded separators
- Configuration file names match their exact casing on disk
- Any embedded resources are referenced with the correct casing

## 7. Test on Target Platforms

If the goal is to run on non-Windows platforms, execute the application on each target OS to catch runtime-only issues:

```bash
dotnet run --configuration Release
```

Test all major code paths, particularly those involving I/O, networking, and external process invocation.

## 8. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent build as appropriate:

**Framework-dependent:**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assets are present before deploying to the target environment.