# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

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

Review the output for any warnings that may indicate deprecated APIs or compatibility issues that did not surface as hard errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been available on .NET Framework but behave differently or throw `PlatformNotSupportedException` at runtime on cross-platform .NET. Review code that uses:

- `System.Drawing` (requires additional packages on Linux/macOS)
- `Microsoft.Win32` registry access
- `System.Security.Permissions`
- COM interop or P/Invoke calls

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package to surface these issues statically.

## 5. Review NuGet Package Versions

Open the `.csproj` file and check that all referenced NuGet packages have versions compatible with your target framework. Run:

```bash
dotnet list package --outdated
```

Update packages where appropriate, and verify that no packages are still targeting `net45`, `net461`, or similar legacy monikers as their only supported framework.

## 6. Test on All Target Platforms

If cross-platform support is a goal, run the application and its tests on each intended operating system (Windows, Linux, macOS) to catch any runtime-only platform issues.

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (`linux-x64`, `osx-x64`, etc.) for your target environment.

## 8. Verify Published Output

Navigate to the `./publish` directory and run the output binary directly to confirm the published artifact works as expected before distributing it.