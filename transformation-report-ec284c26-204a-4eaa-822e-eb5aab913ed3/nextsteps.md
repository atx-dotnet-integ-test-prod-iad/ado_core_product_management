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

Ensure there are no warnings that could indicate deprecated APIs or compatibility issues that were not caught as errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate runtime behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to scan for any APIs that may compile successfully but fail at runtime on non-Windows platforms. Run the following if you have the analyzer installed:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to:
- `System.Windows.Forms` or `System.Web` references, which are not fully cross-platform.
- Registry access (`Microsoft.Win32.Registry`).
- COM interop usage.

## 5. Validate NuGet Package Compatibility

Review all NuGet dependencies in `AdoCore.csproj` and confirm each package supports the target framework. You can check compatibility on [nuget.org](https://www.nuget.org) or by inspecting the package's supported frameworks. Replace any packages that only target `.NET Framework` with their cross-platform equivalents.

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to catch any platform-specific runtime issues that static analysis may not surface:

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
# For a self-contained Linux x64 deployment
dotnet publish --configuration Release --runtime linux-x64 --self-contained true

# For a framework-dependent Windows x64 deployment
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Review the output in the `publish` folder before deploying to your target environment.

## 8. Review Configuration Files

If the project previously used `app.config` or `web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables, as these are the standard configuration mechanisms in modern .NET.