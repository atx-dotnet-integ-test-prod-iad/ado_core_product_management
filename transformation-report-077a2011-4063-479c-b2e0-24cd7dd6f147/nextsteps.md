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

Run a NuGet package restore to confirm all dependencies resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

## 3. Build the Solution

Perform a full build in Release configuration to confirm there are no errors or warnings that were not present during the initial transformation check:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior has been preserved after the migration:

```bash
dotnet test --configuration Release
```

Review the test results carefully. Any failing tests should be investigated to determine whether they indicate a regression introduced by the migration.

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer or review the build output for any `CA1416` platform compatibility warnings. These indicate APIs that may only function correctly on specific operating systems (e.g., Windows-only registry or COM interop calls).

If such APIs exist, consider:
- Wrapping them in `OperatingSystem.IsWindows()` guards.
- Finding cross-platform alternatives in the .NET BCL.

## 6. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` have versions that support your target framework. You can inspect this via:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with cross-platform support.

## 7. Manual Smoke Testing

Run the application manually and exercise its primary functionality to catch any runtime issues that unit tests may not cover:

```bash
dotnet run --configuration Release
```

Pay particular attention to file I/O paths, configuration file loading, and any database or network operations, as these areas commonly surface issues after a cross-platform migration.

## 8. Validate on Target Operating Systems

If the goal is to run on multiple operating systems (e.g., Linux, macOS), test the build and runtime behavior on each target OS:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier (RID) for your target platform.

## 9. Publish the Application

Once validation is complete, publish the application for the intended deployment target:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assemblies and configuration files are present.