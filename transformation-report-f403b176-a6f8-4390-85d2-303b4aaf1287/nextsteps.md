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

Run a NuGet restore to confirm all dependencies resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not support the target framework or that have been deprecated.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types, obsolete APIs, or platform compatibility analyzers (CA1416), as these can indicate runtime issues on specific operating systems.

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in globalization, file path handling, or reflection behavior).

## 5. Check for Windows-Specific API Usage

Run the .NET Compatibility Analyzer or review Platform Compatibility warnings in the build output. Pay particular attention to:

- `System.Data` and ADO.NET provider usage, as some providers (e.g., `System.Data.OleDb`) are Windows-only.
- Registry access (`Microsoft.Win32.Registry`).
- Windows-specific interop or COM components.

If any Windows-only APIs are present, either guard them with runtime checks using `OperatingSystem.IsWindows()` or replace them with cross-platform alternatives.

## 6. Validate ADO.NET Provider Compatibility

Since the project is named `AdoCore`, confirm that the database driver or ADO.NET provider being used has a cross-platform compatible NuGet package. For example:

| Legacy Provider | Cross-Platform Replacement |
|---|---|
| `System.Data.SqlClient` | `Microsoft.Data.SqlClient` |
| `System.Data.OleDb` | Platform-specific; no direct replacement |
| `MySql.Data` | `MySql.Data` (verify version supports .NET 6+/8+) |

Update the relevant `using` statements and package references if a provider swap is required.

## 7. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime-only issues that do not appear at compile time:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime. For a self-contained deployment targeting Linux x64 as an example:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

For a framework-dependent deployment:

```bash
dotnet publish --configuration Release
```

Review the contents of the `publish` output folder before deploying to confirm all required assets are present.