# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build context:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility analyzers, as these can indicate subtle issues introduced during migration.

## 3. Run Existing Tests

If the solution contains test projects, execute the test suite to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully. Failures at this stage may indicate runtime behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime, even when the build succeeds.

## 4. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer or review the build output for any `CA1416` platform compatibility warnings. APIs that were available in .NET Framework may have been removed or may only be available on Windows in cross-platform .NET. Pay particular attention to:

- Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) server-side APIs
- `System.Drawing` (requires additional packages on non-Windows platforms)
- `AppDomain` usage

## 5. Review Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` value is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If the application only needs to run on Windows, consider whether `net8.0-windows` is more appropriate, as it re-enables certain Windows-specific APIs.

## 6. Validate Runtime Behavior

Run the application manually and exercise the primary workflows. Cross-platform .NET has differences in areas such as:

- File path handling (case sensitivity on Linux/macOS)
- Culture and globalization behavior (verify `Invariant Mode` settings in `runtimeconfig.json` if applicable)
- Thread and task scheduling behavior

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime <runtime-identifier> --output ./publish
```

Replace `<runtime-identifier>` with the appropriate value for your target platform, such as `win-x64`, `linux-x64`, or `osx-x64`.

## 8. Review Published Output

Inspect the contents of the publish output directory to confirm all expected assemblies, configuration files, and static assets are present before deploying to the target environment.