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

If the solution contains test projects, execute them to verify behavioral correctness after the migration:

```bash
dotnet test --configuration Release
```

Review test output for failures that may indicate runtime behavioral differences between .NET Framework and cross-platform .NET, such as changes in globalization, reflection, or file path handling.

## 5. Check for Windows-Specific API Usage

Run the .NET Compatibility Analyzer or review Platform Compatibility warnings in the build output. Pay particular attention to:

- `Microsoft.Win32` registry APIs
- `System.Drawing` (GDI+) usage, which requires the `System.Drawing.Common` package and is only supported on Windows in .NET 6+
- `System.Security.Permissions` and Code Access Security (CAS) APIs, which are no-ops in cross-platform .NET
- Any P/Invoke calls targeting Windows-only native libraries

If Windows-only APIs are present and cross-platform support is required, those call sites will need to be replaced with cross-platform alternatives.

## 6. Validate Configuration and App Settings

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or equivalent, and that `System.Configuration.ConfigurationManager` usage (available via the `System.Configuration.ConfigurationManager` NuGet package) is functioning as expected.

## 7. Test on Target Platforms

Run the application on each platform you intend to support (Windows, Linux, macOS) to surface any runtime-only platform issues that static analysis may not catch:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent deployment as appropriate:

**Framework-dependent:**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory and verify the output is complete before deploying to the target environment.