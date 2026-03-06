# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
  </PropertyGroup>
</Project>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Review NuGet Package Versions

Check that all NuGet dependencies in `AdoCore.csproj` are referencing versions compatible with your target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions available using:

```bash
dotnet add package <PackageName> --version <NewVersion>
```

## 4. Run Existing Tests

If a test project exists in the solution, execute the test suite to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Some APIs available in .NET Framework are not available or behave differently in cross-platform .NET. Review the code for usage of the following common problem areas:

- `System.Web` (not available in cross-platform .NET)
- `System.Drawing` (requires additional packages on non-Windows platforms)
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain.CreateDomain` (not supported)
- `BinaryFormatter` (deprecated and disabled by default)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any remaining compatibility issues.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (Windows, Linux, macOS) to catch any platform-specific runtime issues that would not surface during a build.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

**Framework-dependent (requires .NET runtime installed on host):**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (bundles the runtime with the output):**
```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier for your target environment (e.g., `win-x64`, `osx-x64`).

## 8. Verify Published Output

Navigate to the `./publish` directory and confirm all expected files are present. Run the published executable directly to perform a final smoke test before deploying to your target environment.