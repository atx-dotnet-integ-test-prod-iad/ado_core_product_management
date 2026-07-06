# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on all machines that will build or run this project.

## 2. Restore Dependencies

Run a clean restore to confirm all NuGet packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not fully support the target framework. Check for `NU1701` warnings, which indicate a package was restored using a compatibility fallback.

## 3. Build the Solution

Perform a full build in both Debug and Release configurations:

```bash
dotnet build --configuration Debug
dotnet build --configuration Release
```

Confirm there are zero errors and review any warnings that may indicate deprecated APIs or compatibility concerns.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee identical runtime behavior to the original .NET Framework version.

## 5. Audit Platform-Specific API Usage

Use the .NET Compatibility Analyzer or the `dotnet-compatibility` tool to check for any platform-specific API calls that may behave differently or throw `PlatformNotSupportedException` at runtime on non-Windows systems:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Pay particular attention to areas such as:
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific cryptography
- COM interop
- `System.Drawing` (GDI+)

## 6. Test on All Target Platforms

If cross-platform support is a goal, run the application on each target operating system (Windows, Linux, macOS) to surface any runtime issues that static analysis may not catch.

## 7. Review NuGet Package Versions

Check that all referenced NuGet packages have stable releases compatible with your target framework. Replace any packages that have known cross-platform limitations with their recommended alternatives (for example, replacing `System.Drawing.Common` with `SkiaSharp` or `ImageSharp` if image processing is required on Linux).

## 8. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent release build:

```bash
# Framework-dependent
dotnet publish --configuration Release --output ./publish

# Self-contained for a specific runtime
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the contents of the `./publish` directory before deploying to the target environment.