# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If the value still references a Windows-only framework such as `net48` or `net472`, update it accordingly.

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or platform-specific code that compiled but could fail at runtime.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding further.

## 4. Check for Platform-Specific API Usage

Even when a project compiles without errors, it may contain APIs that are only supported on Windows. Use the .NET Compatibility Analyzer to surface these at build time by adding the following to `AdoCore.csproj`:

```xml
<PropertyGroup>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <AnalysisMode>All</AnalysisMode>
</PropertyGroup>
```

Rebuild and review any `CA1416` (platform compatibility) warnings that appear.

## 5. Validate NuGet Dependencies

Confirm that all referenced NuGet packages support the target framework:

```bash
dotnet list package --outdated
dotnet list package --deprecated
```

Update or replace any packages that do not have a compatible version for your target framework.

## 6. Perform Runtime Validation

Run the application on each target platform (Windows, Linux, macOS) to catch any runtime-only issues such as file path separators, registry access, or Windows-specific interop calls:

```bash
dotnet run --configuration Release
```

Pay particular attention to:
- File I/O operations using hardcoded backslashes (`\`); replace with `Path.Combine` or `Path.DirectorySeparatorChar`.
- Any calls into `Microsoft.Win32` namespaces.
- P/Invoke calls targeting Windows-only native libraries.

## 7. Review Configuration Files

If the project previously used `App.config` or `Web.config`, verify that settings have been migrated to `appsettings.json` or environment variables, as `ConfigurationManager` behavior differs in cross-platform .NET.

## 8. Publish a Release Build

Once validation is complete, publish the application for your target runtime:

```bash
# Framework-dependent (requires .NET runtime installed on target machine)
dotnet publish --configuration Release --output ./publish

# Self-contained for a specific runtime identifier
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the contents of the `./publish` directory and run the output binary on the target machine to confirm correct behavior.