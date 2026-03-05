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

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility analyzers, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute the full test suite:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any test failures that were not present before the migration should be investigated, as they may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Verify Platform-Specific API Usage

Use the .NET Compatibility Analyzer to check for any APIs that may behave differently or are unsupported on non-Windows platforms. You can enable this by ensuring the following is set in your project files:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

Pay particular attention to:
- `System.Drawing` usage (requires additional packages on Linux/macOS)
- Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) server-side APIs
- Any P/Invoke calls to native Windows libraries

## 5. Review Target Framework Monikers

Open each `.csproj` file and confirm the `<TargetFramework>` value is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If any project still references `net472` or similar legacy monikers, update them accordingly.

## 6. Check Configuration and App Settings

If the project previously used `App.config` or `Web.config`, verify that settings have been migrated to `appsettings.json` or the appropriate .NET configuration model. The legacy XML-based configuration system has limited support in cross-platform .NET.

## 7. Validate Runtime Behavior

Run the application manually and exercise its primary workflows. Compare the output and behavior against the legacy version to confirm functional equivalence. Pay attention to:
- Serialization and deserialization behavior
- Culture and locale-sensitive operations
- File path handling, which differs between Windows and Unix-based systems (`\` vs `/`)

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime, use:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Replace `win-x64` with the appropriate Runtime Identifier (RID) for your target platform, such as `linux-x64` or `osx-x64`.

## 9. Review Published Output

Inspect the contents of the publish output directory to confirm all expected assemblies, configuration files, and static assets are present before deploying to the target environment.