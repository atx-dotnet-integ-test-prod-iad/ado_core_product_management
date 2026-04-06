# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework is set to the intended cross-platform .NET version (e.g., `net6.0`, `net7.0`, or `net8.0`):

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. You can check your installed SDKs by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all dependencies resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts that may not surface as hard build errors but could cause runtime issues.

## 3. Build the Solution

Perform a full build in Release configuration to confirm there are no configuration-specific issues:

```bash
dotnet build --configuration Release
```

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review the test output carefully. Pay particular attention to any tests that interact with platform-specific APIs (e.g., Windows registry, COM interop, or Windows-only file paths), as these may fail on non-Windows platforms.

## 5. Check for Platform-Specific API Usage

Even without build errors, the code may use APIs that are only available on Windows. Use the .NET Compatibility Analyzer to surface these at build time by adding the following to `AdoCore.csproj`:

```xml
<PropertyGroup>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <AnalysisMode>All</AnalysisMode>
</PropertyGroup>
```

Rebuild after adding this and review any new warnings or errors related to platform compatibility.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (e.g., Linux, macOS) to identify any runtime failures that would not appear during a Windows build:

```bash
dotnet run --configuration Release
```

## 7. Review NuGet Package Compatibility

Check that all referenced NuGet packages support the target framework. Visit [nuget.org](https://www.nuget.org) for each dependency and confirm `.NET` compatibility. Replace any packages that only support `.NET Framework` with their cross-platform equivalents where necessary.

## 8. Publish the Application

Once validation is complete, publish the application for your target runtime. For a self-contained deployment targeting Linux x64 as an example:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

For a framework-dependent deployment:

```bash
dotnet publish --configuration Release
```

The output will be placed in the `bin/Release/<targetframework>/publish/` directory and can be deployed to the target environment.