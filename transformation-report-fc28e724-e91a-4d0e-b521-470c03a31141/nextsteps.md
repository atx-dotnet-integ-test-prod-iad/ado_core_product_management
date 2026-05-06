# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine by running:

```bash
dotnet --version
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a full NuGet restore to ensure all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any dependency conflicts or packages that may have been resolved to unexpected versions.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review all warnings in the build output. While warnings do not block compilation, some may indicate deprecated APIs or compatibility concerns that should be addressed before deployment.

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify functional correctness after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Pay close attention to any tests that were previously passing in the legacy project but now fail, as these may indicate behavioral differences between .NET Framework and cross-platform .NET.

## 5. Check for Platform-Specific API Usage

Review the codebase for any APIs that were available in .NET Framework but have limited or no support in cross-platform .NET. Common areas to check include:

- `System.Web` references
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage
- `BinaryFormatter` (deprecated and disabled by default in modern .NET)
- COM interop dependencies

You can use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package to surface these issues statically.

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement. Pay attention to:

- File path separators (`\` vs `/`)
- Case sensitivity of the file system on Linux
- Environment variable differences across operating systems

## 7. Review NuGet Package Versions

Confirm that all NuGet packages referenced in `AdoCore.csproj` have versions compatible with your target framework. Check the [NuGet package page](https://www.nuget.org/) for each dependency to verify TFM compatibility.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier (RID) for your deployment target:

**Framework-dependent deployment:**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained deployment (example for Linux x64):**
```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files are present before deploying to the target environment.