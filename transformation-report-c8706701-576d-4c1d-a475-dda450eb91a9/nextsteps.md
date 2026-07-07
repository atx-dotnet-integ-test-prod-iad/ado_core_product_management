# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on all machines that will build or run this project.

## 2. Restore Dependencies

Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts.

## 3. Build the Solution

Perform a full build to confirm no errors surface outside of the IDE:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings (CA1416).

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee functional correctness.

## 5. Check for Windows-Specific API Usage

Even without build errors, the code may contain APIs that only function on Windows. Run the .NET Compatibility Analyzer to surface these:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Look for diagnostics prefixed with `CA1416` and evaluate whether those code paths need platform guards or alternative implementations.

## 6. Validate Runtime Behavior on Target Platforms

If cross-platform execution is a goal, run the application on each target operating system (Windows, Linux, macOS) and verify:

- File path handling uses `Path.Combine` and does not rely on hardcoded backslashes.
- Any registry, COM interop, or Windows-specific service calls are either removed or guarded with `RuntimeInformation.IsOSPlatform(OSPlatform.Windows)`.
- Configuration file paths and environment variables resolve correctly per platform.

## 7. Review NuGet Package Compatibility

Check that all referenced NuGet packages support your target TFM. Visit [nuget.org](https://www.nuget.org) for each dependency and confirm `.NET 6`, `.NET 7`, or `.NET 8` compatibility as applicable. Replace any packages that only support `.NET Framework` with their cross-platform equivalents.

## 8. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent release:

```bash
# Framework-dependent
dotnet publish --configuration Release --output ./publish

# Self-contained for a specific runtime
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the output in the `./publish` directory runs correctly on the target machine before promoting to production.