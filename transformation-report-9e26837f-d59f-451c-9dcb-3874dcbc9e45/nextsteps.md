# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this matches the version of the .NET SDK you have installed. You can verify your installed SDKs by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not support the target framework or that have been replaced by inbox .NET APIs.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface at this stage, particularly those related to obsolete APIs or platform compatibility analyzers (CA1416, etc.).

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` result files for any failures or skipped tests that may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 5. Check for Windows-Specific API Usage

Run the .NET Compatibility Analyzer or the `Microsoft.DotNet.ApiCompat` tooling to identify any remaining calls to Windows-only APIs that may fail on non-Windows platforms:

```bash
dotnet add package Microsoft.Windows.Compatibility
```

If the project is intended to run on Windows only, adding the above package is sufficient. If true cross-platform support is required, replace or abstract any Windows-specific calls (e.g., registry access, Windows event log, COM interop).

## 6. Validate Configuration and App Settings

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables, as `ConfigurationManager` behavior differs under cross-platform .NET. Verify the following:

- Connection strings are accessible at runtime.
- Any `<appSettings>` keys have been moved to the appropriate configuration provider.

## 7. Smoke Test Core Functionality

Execute the application manually or through integration tests against a representative workload to confirm that the primary data access and business logic paths behave as expected under the new runtime.

## 8. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent release build:

**Framework-dependent:**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the contents of the `./publish` directory before deploying to the target environment.