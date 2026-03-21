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

Review the output for any warnings about deprecated packages or packages that could not be resolved. If any packages reference old `net4x` or Windows-specific libraries, consider finding cross-platform alternatives on [NuGet](https://www.nuget.org).

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review the build output for any warnings, particularly:
- `CS0618` (obsolete API usage)
- `CS8600`–`CS8629` (nullable reference warnings)
- Platform compatibility warnings such as `CA1416`

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify existing behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences introduced by the migration to cross-platform .NET.

## 5. Check for Windows-Specific API Usage

Even without build errors, some APIs may only fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these issues:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to any `CA1416` warnings, which indicate platform-specific API calls that will throw on Linux or macOS.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to catch any runtime issues that static analysis may not surface.

```bash
dotnet run --configuration Release
```

## 7. Verify Configuration and File Paths

Check that any file paths, directory separators, or environment-specific configuration values in the code use cross-platform equivalents:

- Replace hardcoded backslashes (`\`) with `Path.Combine()` or `Path.DirectorySeparatorChar`
- Replace `Environment.GetFolderPath` calls with cross-platform equivalents where applicable

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

**Framework-dependent (requires .NET runtime on target machine):**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (bundles the runtime):**
```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, `osx-arm64`, etc.) as needed. A full list of runtime identifiers is available in the [Microsoft RID catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).