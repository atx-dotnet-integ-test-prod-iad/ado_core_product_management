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

Review the output for any warnings related to deprecated packages or version conflicts.

## 3. Build the Solution

Perform a full build to confirm there are no issues beyond what was captured in the error report:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings (CA1416).

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify behavioral correctness after the migration:

```bash
dotnet test --configuration Release
```

Review any failing tests to determine whether they are caused by API differences between .NET Framework and modern .NET.

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer to identify any APIs that may not be supported on all target platforms. Pay particular attention to:

- `System.Data` usage, since this project appears to be ADO-related (`AdoCore`)
- Any registry, COM interop, or Windows-specific APIs that may have been used in the original project

You can enable the analyzer by ensuring the following is present in the `.csproj`:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

## 6. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (Windows, Linux, macOS) to catch any runtime behavior differences that static analysis may not surface.

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require .NET to be installed on the target machine:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier for your target environment (e.g., `win-x64`, `osx-x64`).

## 8. Review Output Artifacts

Inspect the contents of the publish output directory to confirm all expected assemblies, configuration files, and dependencies are present before deploying to the target environment.