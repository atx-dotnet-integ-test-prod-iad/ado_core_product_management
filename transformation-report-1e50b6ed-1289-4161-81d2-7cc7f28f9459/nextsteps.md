# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this aligns with the runtime version available in your target environment.

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not block the build.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior has not changed after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs that compiled successfully may throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Review the code for usage of the following:

- `System.Drawing` (GDI+)
- `Microsoft.Win32` registry APIs
- Windows Communication Foundation (WCF) server-side APIs
- `AppDomain.CreateDomain`
- COM interop

Use the [.NET Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to assist with identifying these cases.

## 5. Review NuGet Package Versions

Open the `.csproj` file and review all `<PackageReference>` entries. Confirm that:

- No packages are pinned to versions that only support .NET Framework.
- Packages have been updated to their latest stable versions compatible with your target framework.

```bash
dotnet list package --outdated
```

## 6. Validate Configuration Files

If the project previously used `App.config` or `Web.config`, verify that settings have been migrated to `appsettings.json` or the appropriate .NET configuration system. The legacy XML-based configuration system has limited support in cross-platform .NET.

## 7. Perform Runtime Smoke Testing

Run the application locally and exercise its primary code paths. Pay attention to:

- File I/O operations that may use Windows-style path separators (`\`)
- Culture and encoding assumptions
- Thread and synchronization behavior

Use `Path.Combine` and `Path.DirectorySeparatorChar` for any path construction to ensure cross-platform compatibility.

## 8. Publish the Application

Once validation is complete, publish the application using the following command, adjusting the runtime identifier (`-r`) as needed:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment:

```bash
dotnet publish --configuration Release --self-contained true -r win-x64 --output ./publish
```

Refer to the [.NET RID catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog) for a full list of supported runtime identifiers.