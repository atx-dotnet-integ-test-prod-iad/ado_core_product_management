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

Address any warnings that surface at this stage, particularly those related to obsolete APIs or platform-specific code paths.

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify behavioral correctness after the migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee runtime correctness, so any failing tests should be investigated before proceeding.

## 5. Check for Platform-Specific Code

Search the codebase for any remaining usage of Windows-specific APIs that may not be available on Linux or macOS, such as:

- `System.Windows.Forms`
- `Microsoft.Win32` registry access
- COM interop
- P/Invoke calls targeting Windows-only system libraries

These will not cause build errors if the target platform is Windows, but they will cause runtime failures on other platforms. Use the .NET Platform Compatibility Analyzer warnings as a guide.

## 6. Review `app.config` / `web.config` Usage

Legacy configuration files are not fully supported in modern .NET. Confirm that any configuration previously held in `app.config` has been migrated to `appsettings.json` or another supported configuration provider.

## 7. Validate Runtime Behavior

Run the application locally and exercise its primary code paths:

```bash
dotnet run --configuration Release
```

Compare output and behavior against the original .NET Framework version to identify any regressions.

## 8. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent release:

**Framework-dependent:**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory and confirm all required assets are present before deploying to the target environment.