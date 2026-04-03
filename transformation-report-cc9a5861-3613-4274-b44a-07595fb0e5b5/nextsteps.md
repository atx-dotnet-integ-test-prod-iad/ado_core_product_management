# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). For example:

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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if they do not produce build errors.

## 3. Review NuGet Package Versions

Check that all NuGet dependencies referenced in `AdoCore.csproj` are targeting .NET-compatible versions. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework.

## 4. Run Existing Tests

If the solution contains test projects, execute the test suite to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and modern .NET.

## 5. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been replaced with cross-platform equivalents that behave differently at runtime. Pay particular attention to:

- File system path handling (`Path.Combine` vs hardcoded separators)
- Registry access (`Microsoft.Win32.Registry`) — not available on Linux/macOS
- `System.Drawing` — requires additional native dependencies on non-Windows platforms
- WCF or Remoting usage — not fully supported in modern .NET

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.ApiCompat` tooling to surface any such usages.

## 6. Validate Runtime Behavior

Run the application manually and exercise its primary workflows. Compare the output and behavior against the legacy version to confirm functional equivalence.

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

If a self-contained deployment is required (no .NET runtime needed on the target machine), use:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier for your target platform (e.g., `linux-x64`, `osx-x64`).

## 8. Verify Output on Target Machine

Copy the published output to the target environment and run the application there. Confirm that all dependencies are resolved and the application starts and operates correctly.