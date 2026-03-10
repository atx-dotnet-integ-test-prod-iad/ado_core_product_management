# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts. If any packages previously relied on Windows-specific implementations, verify that cross-platform compatible alternatives are in place.

## 3. Build the Solution

Perform a full build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Review all warnings in the output, as some may indicate API usage that is not fully supported across all platforms.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully. Failures may indicate platform-specific behavior differences between the legacy .NET Framework and the new cross-platform .NET runtime, particularly around:

- File path separators
- Registry access (not available on Linux/macOS)
- Windows-specific APIs (`System.Drawing`, COM interop, etc.)
- Culture and encoding defaults

## 5. Validate Platform-Specific API Usage

Search the codebase for APIs that may not be supported on non-Windows platforms. The .NET Compatibility Analyzer can assist with this. Add the following to your project file if not already present:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

Rebuild and review any new analyzer warnings related to platform compatibility.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application for your target platform:

**Framework-dependent (requires .NET runtime installed on target machine):**

```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (bundles the runtime with the output):**

```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, `osx-arm64`, etc.) as needed.

Review the contents of the `./publish` directory to confirm all expected files are present before deploying to the target environment.