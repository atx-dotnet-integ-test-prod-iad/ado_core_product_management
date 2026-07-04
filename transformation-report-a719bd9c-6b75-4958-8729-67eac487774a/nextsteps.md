# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine by running:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly against the new target framework:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not support the target framework or that have been replaced by inbox .NET APIs.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings introduced after the restore step:

```bash
dotnet build --configuration Release
```

Address any warnings related to deprecated APIs or platform compatibility analyzers, as these may indicate runtime issues even when the build succeeds.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may point to behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in globalization, file path handling, or reflection behavior).

## 5. Check for Platform-Specific API Usage

Run the .NET Compatibility Analyzer or the `dotnet-apicompat` tool to identify any remaining usage of Windows-only or platform-specific APIs:

```bash
dotnet add package Microsoft.DotNet.ApiCompat
```

Additionally, review any code that uses the following, as these commonly require attention after migration:

- `System.Windows.Forms` or `System.Web` (not available cross-platform)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions (backslashes, drive letters)
- `AppDomain` usage that is not supported in .NET Core and later

## 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that static analysis may not catch.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

**Framework-dependent (requires .NET runtime installed on target machine):**
```bash
dotnet publish --configuration Release
```

**Self-contained (bundles the runtime with the application):**
```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier for your target platform (e.g., `win-x64`, `osx-x64`, `osx-arm64`).

## 8. Review Output Artifacts

After publishing, verify the output directory contains all expected files and that the application starts correctly on the target machine:

```bash
dotnet ./AdoCore.dll
```

Or, if published as a self-contained executable, run the native executable directly.