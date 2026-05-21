# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version you intend to support.

## 2. Restore NuGet Packages

Run the following command from the solution root to ensure all dependencies are restored cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or incompatible packages.

## 3. Build the Solution

Perform a full build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or obsolete API usage.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review the test output and ensure all previously passing tests continue to pass.

## 5. Verify Platform-Specific Code

Check the codebase for any APIs that were previously Windows-only, such as:

- `System.Windows.Forms`
- `Microsoft.Win32` registry access
- COM interop
- P/Invoke calls targeting Windows-specific libraries

If any such APIs are present, consider using platform guards (`RuntimeInformation.IsOSPlatform`) or replacing them with cross-platform alternatives.

## 6. Run on Target Platforms

If cross-platform support is a goal, manually run the application on each intended platform (Linux, macOS, Windows) to surface any runtime issues that do not appear at compile time:

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application for your target runtime. For a self-contained, platform-specific publish:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed. Review the output directory to confirm all required files are present.

## 8. Review Removed or Changed APIs

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any remaining compatibility concerns that may only surface at runtime.