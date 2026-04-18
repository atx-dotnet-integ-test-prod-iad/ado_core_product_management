# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy the migrated project.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net48`, `netcoreapp`, or other legacy monikers unless intentionally targeting multiple frameworks.

## 2. Restore Dependencies

Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved references.

## 3. Build the Solution

Perform a full build to confirm there are no warnings that may indicate compatibility issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility analyzers.

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify runtime behavior matches the pre-migration state:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failed or skipped tests and investigate regressions.

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer or review the build output for `CA1416` warnings, which indicate APIs that are only available on specific operating systems (e.g., Windows-only registry or WinForms APIs). If any are found, add appropriate runtime guards:

```csharp
if (OperatingSystem.IsWindows())
{
    // Windows-specific code
}
```

## 6. Validate Configuration and App Settings

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables as appropriate for .NET. Verify that `ConfigurationManager` usage, if any, is handled by the `System.Configuration.ConfigurationManager` NuGet package or replaced with `Microsoft.Extensions.Configuration`.

## 7. Smoke Test the Application

Run the application locally against a representative workload or dataset to confirm end-to-end functionality:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Verify that database connections, file I/O paths, and any network calls behave as expected on the target platform.

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` identifier (`win-x64`, `osx-x64`, etc.) and `--self-contained` flag to match your deployment environment. Review the output in the `publish` folder before deploying to the target machine.