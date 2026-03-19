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

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility, as these can indicate subtle issues introduced during migration.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during the migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated to determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Verify Platform-Specific API Usage

Cross-platform .NET does not support certain Windows-specific APIs. Use the .NET Compatibility Analyzer to identify any remaining platform-specific calls:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Review analyzer output in your IDE or build logs and replace or conditionally compile any flagged APIs.

## 5. Check Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to an appropriate and currently supported version, such as `net8.0`:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If the project needs to support multiple frameworks, use `<TargetFrameworks>` (plural) with a semicolon-separated list.

## 6. Review Configuration Files

If the original project used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or equivalent .NET configuration mechanisms. The legacy XML-based configuration system has limited support in cross-platform .NET.

## 7. Validate Runtime Behavior

Run the application manually and exercise its primary workflows. Pay particular attention to:

- File path handling, as path separators differ between Windows and Unix-based systems.
- Registry access, which is not available on non-Windows platforms.
- Any use of `System.Drawing` or other packages that may require additional native dependencies on Linux or macOS.

## 8. Publish the Application

Once validation is complete, publish the application using the following command, adjusting the runtime identifier as needed:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

For a self-contained deployment that bundles the .NET runtime:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true
```

Replace `win-x64` with the appropriate runtime identifier for your target platform, such as `linux-x64` or `osx-x64`.