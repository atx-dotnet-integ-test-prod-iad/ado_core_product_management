# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net6.0`, `net7.0`, or `net8.0`):

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

Ensure there are no warnings that could indicate compatibility issues, such as obsolete API usage or platform-specific code paths.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific Code

Search the codebase for APIs that were available in .NET Framework but have been removed or altered in cross-platform .NET. Common areas to inspect include:

- `System.Web` usage (not available in cross-platform .NET)
- `AppDomain` APIs with limited support
- Windows Registry access (`Microsoft.Win32.Registry`)
- `BinaryFormatter` (deprecated and disabled by default)
- COM interop or P/Invoke calls targeting Windows-only libraries

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package if needed.

## 5. Validate NuGet Package Compatibility

Review all NuGet dependencies in `AdoCore.csproj` and confirm each package targets `netstandard2.0`, `netstandard2.1`, or the specific .NET version you are using. Packages that only support `net45`, `net472`, etc., may not function correctly.

```bash
dotnet list package --outdated
```

Update any outdated packages where a compatible version exists.

## 6. Test on Target Platforms

Since the goal is cross-platform support, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues:

```bash
dotnet run --configuration Release
```

Pay particular attention to:
- File path separators (`/` vs `\`)
- Case-sensitive file systems (Linux)
- Environment variable differences

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

**Framework-dependent (requires .NET runtime installed on target machine):**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (bundles the .NET runtime):**
```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate RID for your target platform (e.g., `win-x64`, `osx-x64`, `osx-arm64`).

## 8. Review Output Artifacts

Inspect the `./publish` directory to confirm all expected files are present, including configuration files, static assets, and dependencies. Verify the application starts correctly from the published output before promoting it to any environment.