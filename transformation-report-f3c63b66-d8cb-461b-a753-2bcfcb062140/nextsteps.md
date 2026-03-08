# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. Run the following to confirm your SDK version:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

## 3. Build the Solution

Perform a full build to confirm there are no compilation errors:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during the build, particularly those related to nullable reference types or platform compatibility.

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite to verify existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review the test results and investigate any failures. If no test project exists, consider writing unit tests that cover the core functionality of `AdoCore` before proceeding further.

## 5. Check for Platform-Specific API Usage

Since this was a legacy project migration, audit the codebase for any APIs that were Windows-specific. You can use the .NET Compatibility Analyzer to assist with this. Look for:

- `System.Windows.Forms` or `System.Drawing` references that may require the `-windows` TFM suffix (e.g., `net8.0-windows`)
- P/Invoke calls targeting Windows-only native libraries
- Registry access via `Microsoft.Win32`

If Windows-specific APIs are required, update the TFM accordingly:

```xml
<TargetFramework>net8.0-windows</TargetFramework>
```

## 6. Review NuGet Package Versions

Check that all NuGet packages referenced in `AdoCore.csproj` have versions compatible with the target framework. Replace any packages that have known cross-platform replacements. For example:

- Replace `System.Data.SqlClient` with `Microsoft.Data.SqlClient`
- Replace any packages targeting `net4x` only with their modern equivalents

## 7. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement:

```bash
dotnet run --configuration Release
```

Test the primary workflows manually and compare output against the legacy application to confirm behavioral parity.

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime. For a self-contained deployment targeting Linux x64 as an example:

```bash
dotnet publish -c Release -r linux-x64 --self-contained true
```

For a framework-dependent deployment:

```bash
dotnet publish -c Release
```

Review the contents of the `publish` output folder to confirm all required assets are present before deploying to the target environment.