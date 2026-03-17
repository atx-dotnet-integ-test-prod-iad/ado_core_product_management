# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. Run the following to confirm:

```bash
dotnet --version
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not fully support the target framework. Consider replacing packages flagged with compatibility warnings with actively maintained alternatives where applicable.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review all warnings in the build output, as some warnings in cross-platform .NET may indicate runtime issues that do not surface as errors.

## 4. Run Existing Tests

If the solution contains test projects, execute them to validate that existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Investigate any failing tests to determine whether they reflect regressions introduced during the transformation or pre-existing issues.

## 5. Validate Platform-Specific Code

Search the codebase for any APIs that were commonly unavailable or changed in cross-platform .NET, including:

- `System.Windows.Forms` or `System.Drawing` (requires explicit package references or may not be applicable outside Windows)
- `Microsoft.Win32` registry access
- `AppDomain` members with limited support
- P/Invoke calls targeting Windows-specific native libraries

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining compatibility concerns.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any runtime-only issues that do not appear at compile time.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier (RID) for your deployment target.

**Framework-dependent deployment:**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained deployment (example for Linux x64):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Refer to the [.NET RID catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog) for a full list of supported runtime identifiers.

## 8. Review Output Artifacts

Confirm the contents of the publish output directory are complete and that the application starts correctly from the published location before distributing or deploying to any environment.