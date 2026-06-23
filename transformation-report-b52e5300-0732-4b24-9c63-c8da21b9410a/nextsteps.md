# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any test failures should be investigated before proceeding, as they may indicate runtime behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Verify Platform-Specific API Usage

Cross-platform .NET does not support certain Windows-specific APIs. Run the .NET Compatibility Analyzer to surface any remaining platform-specific calls:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Review any warnings produced by the analyzer and replace or conditionally compile any APIs that are not supported on your target platforms.

## 5. Check Configuration and App Settings

If the project uses `App.config` or `Web.config`, verify that settings have been migrated to the appropriate `appsettings.json` or `appsettings.{Environment}.json` format, as `System.Configuration` support is limited in cross-platform .NET.

## 6. Validate Runtime Behavior

Run the application manually and exercise its primary workflows. Pay particular attention to:

- File path handling, as path separators differ between Windows and Unix-based systems.
- Reflection-based code, which may behave differently under the new runtime.
- Any use of `AppDomain`, `Remoting`, or `BinaryFormatter`, which are restricted or removed in modern .NET.

## 7. Review Target Framework Moniker (TFM)

Open each `.csproj` file and confirm the `<TargetFramework>` value is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If any projects still reference `net472` or similar legacy TFMs, update them to a supported cross-platform TFM.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with your target runtime identifier (e.g., `win-x64`, `osx-x64`) as needed. Review the publish output directory to confirm all required assets are present.