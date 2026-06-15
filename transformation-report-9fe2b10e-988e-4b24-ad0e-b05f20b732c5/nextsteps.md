# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly under the new TFM:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not support the target framework or that have been replaced by inbox .NET APIs.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to obsolete APIs or platform-specific code paths.

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify behavioral correctness after the migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee runtime correctness, so test coverage is important at this stage.

## 5. Check for Platform-Specific Code

Search the codebase for any remaining Windows-specific APIs or references that may compile successfully but fail at runtime on non-Windows platforms. Common areas to check include:

- `System.Windows.Forms` or `System.Drawing` usage
- Registry access via `Microsoft.Win32`
- COM interop or P/Invoke calls
- File path separators hardcoded as `\`

Use the .NET Compatibility Analyzer to assist with this:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

## 6. Review Removed or Changed APIs

Check the [.NET API compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) for any APIs used in the project that have breaking changes or have been removed between the legacy .NET Framework version and the current .NET version.

## 7. Validate Runtime Behavior

Run the application manually and exercise its primary workflows. Pay particular attention to:

- File I/O operations and path handling
- Configuration file loading (e.g., migration from `app.config` to `appsettings.json`)
- Database connectivity if ADO.NET or an ORM is in use
- Any reflection-based code that may behave differently under the new runtime

## 8. Publish the Application

Once validation is complete, publish the application for your target platform:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value, for example `win-x64`, `linux-x64`, or `osx-x64`. Use `--self-contained true` if you want the output to include the .NET runtime.

Review the publish output directory to confirm all required assets are present before deploying.