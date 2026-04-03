# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

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

Review the output for any warnings related to deprecated or missing packages.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during the build, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify that existing behavior has been preserved after the transformation:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated to determine whether they indicate a regression introduced during the migration.

## 5. Verify Platform-Specific Code

Search the codebase for any APIs that were previously Windows-only and may not behave identically on Linux or macOS. Common areas to check include:

- File path separators (`\` vs `/`) — use `Path.Combine` and `Path.DirectorySeparatorChar` where applicable.
- Registry access (`Microsoft.Win32.Registry`) — not available on non-Windows platforms.
- Windows-specific interop (`DllImport` with system DLLs such as `kernel32.dll`, `user32.dll`).
- `System.Drawing` — has platform limitations outside of Windows.

Use the [.NET Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to surface platform-specific API usage automatically.

## 6. Check Configuration and Runtime Behavior

- Confirm that any configuration files (e.g., `appsettings.json`, `app.config`) are correctly read at runtime on the target platform.
- If `app.config` was used in the legacy project, verify that the relevant settings have been migrated to `appsettings.json` or another supported configuration mechanism.

## 7. Publish the Application

Once validation is complete, publish the application for the desired target platform:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained true
```

Replace `<runtime-identifier>` with the appropriate RID, for example:

| Platform | RID |
|---|---|
| Windows x64 | `win-x64` |
| Linux x64 | `linux-x64` |
| macOS x64 | `osx-x64` |
| macOS ARM64 | `osx-arm64` |

The published output will be located in `bin/Release/<tfm>/<rid>/publish/`.

## 8. Smoke Test the Published Output

Run the published binary directly on the target platform to confirm it starts and operates correctly outside of the development environment:

```bash
./AdoCore
```

Verify that all runtime dependencies are present and that no `DllNotFoundException` or `PlatformNotSupportedException` errors occur at startup or during normal operation.