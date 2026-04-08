# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts. If any packages still reference old `net4x` or Windows-only libraries, consider finding cross-platform alternatives on [NuGet](https://www.nuget.org).

## 3. Build the Solution

Perform a full build in Release configuration to confirm there are no compile-time issues:

```bash
dotnet build --configuration Release
```

Review all warnings in the output, as some may indicate runtime issues that do not surface as errors.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify functional correctness:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime, particularly around:

- `System.Data` and ADO.NET behavior differences
- Culture and encoding defaults
- File path handling (`Path.DirectorySeparatorChar`)
- Reflection behavior changes

## 5. Validate Cross-Platform Behavior

Since the goal is cross-platform compatibility, test the application on each target operating system (Windows, Linux, macOS) if applicable:

```bash
dotnet run --configuration Release
```

Pay particular attention to:

- File I/O operations that may use hardcoded Windows-style paths
- Registry access calls, which are not available on Linux/macOS
- Any P/Invoke or native interop code that references Windows-specific DLLs
- `System.Drawing` usage, which may require additional native dependencies on non-Windows platforms

## 6. Check for Removed or Obsolete APIs

Run the .NET Compatibility Analyzer to surface any API usage that may cause issues at runtime:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
dotnet build
```

Alternatively, use the [.NET Upgrade Assistant](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) to scan for remaining compatibility concerns:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze
```

## 7. Review Configuration Files

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables where appropriate, as some `System.Configuration` APIs behave differently or are unavailable in cross-platform .NET.

## 8. Publish the Application

Once validation is complete, publish the application for your target platform:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, `osx-arm64`, etc.) as needed. Use `--self-contained true` if you want the output to include the .NET runtime, or `--self-contained false` if the runtime will be installed separately on the target machine.