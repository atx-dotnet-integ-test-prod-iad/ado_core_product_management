# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine by running:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any dependency conflicts or packages that could not be resolved.

## 3. Build the Solution

Perform a full build to confirm no errors surface at compile time:

```bash
dotnet build --configuration Release
```

Address any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not block the build.

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release
```

Review test results carefully. Failures here may indicate behavioral differences introduced by the migration that did not surface as build errors.

## 5. Verify Platform-Specific Code

Search the codebase for any APIs that were previously Windows-only and may now throw `PlatformNotSupportedException` at runtime on non-Windows systems. Common areas to check include:

- `System.Drawing` (GDI+)
- `Microsoft.Win32` registry access
- Windows Communication Foundation (WCF) server-side APIs
- COM interop calls

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package to identify these usages if needed.

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear in a Windows-only build and test pass.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier (RID) for your target environment:

**Framework-dependent (requires .NET runtime installed on target machine):**
```bash
dotnet publish --configuration Release
```

**Self-contained (bundles the runtime with the output):**
```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64
```

Replace `linux-x64` with the appropriate RID for your target platform (e.g., `win-x64`, `osx-x64`, `osx-arm64`).

Review the contents of the `publish` output directory to confirm all required files are present before deploying to the target environment.