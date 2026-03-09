# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

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

Review the output for any warnings about deprecated packages or packages that do not support the target framework. Replace any packages that only support `net4x` or older frameworks with their cross-platform equivalents.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review any warnings in the build output, as some warnings may indicate runtime issues that do not prevent compilation.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review all test results and investigate any failures. Pay particular attention to tests that cover platform-specific functionality such as file I/O paths, registry access, or Windows-specific APIs.

## 5. Check for Platform-Specific API Usage

Even without build errors, the code may reference APIs that only function correctly on Windows. Use the .NET Compatibility Analyzer to surface these at build time by adding the following to `AdoCore.csproj`:

```xml
<PropertyGroup>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <AnalysisMode>All</AnalysisMode>
</PropertyGroup>
```

Rebuild and review any new analyzer warnings, particularly those prefixed with `CA1416` (platform compatibility).

## 6. Validate Runtime Behavior on Target Platforms

Run the application on each platform you intend to support, for example Windows, Linux, and macOS:

```bash
dotnet run --configuration Release
```

Test all major code paths, especially those that previously relied on Windows-specific behavior such as:
- File path separators
- Windows registry access
- COM interop
- Windows Authentication

## 7. Publish a Self-Contained Build

Once runtime validation is complete, produce a self-contained publish to confirm the output is deployable:

```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish/linux-x64
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish/win-x64
```

Verify the contents of the output directories and confirm the application runs correctly from the published output on the respective platforms.

## 8. Review Removed or Changed APIs

Consult the [.NET Upgrade Assistant compatibility reports](https://learn.microsoft.com/en-us/dotnet/core/porting/) and the [.NET API compatibility browser](https://learn.microsoft.com/en-us/dotnet/api/) to confirm that any APIs used in the project are fully supported in the target framework version.