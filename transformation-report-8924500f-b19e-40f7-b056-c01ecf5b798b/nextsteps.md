# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this is consistent with any dependent or consuming projects in the solution.

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not cause build failures.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior has not changed after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any APIs that may compile successfully but fail at runtime on non-Windows platforms. Pay particular attention to:

- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific interop (`System.Runtime.InteropServices`)
- `System.Drawing` (requires `System.Drawing.Common` and may have platform restrictions)
- WCF or Remoting usage

## 5. Validate NuGet Package Compatibility

Review all NuGet packages referenced in `AdoCore.csproj` and confirm they support the target framework. You can check compatibility on [nuget.org](https://www.nuget.org) or by inspecting the package's supported frameworks.

```bash
dotnet list package --outdated
```

Update any outdated packages that have newer versions with cross-platform support.

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application or test suite on each intended platform (Windows, Linux, macOS) to surface any runtime-only issues that do not appear at compile time.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) as needed. Use `--self-contained true` if you require the .NET runtime to be bundled with the output.

## 8. Review Output Artifacts

Inspect the `publish` output directory to confirm all expected assemblies, configuration files, and assets are present before deploying to the target environment.