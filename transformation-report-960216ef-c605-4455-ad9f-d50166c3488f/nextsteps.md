# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if the build succeeds.

## 3. Review NuGet Package Versions

Open the `.csproj` file and check all `<PackageReference>` entries. Ensure each package:
- Has a version compatible with your target framework.
- Is not a Windows-only package (e.g., packages referencing `System.Windows` or `Microsoft.Win32`) if cross-platform support is required.

You can check compatibility using the [NuGet Package Explorer](https://www.nuget.org/packages) or by running:

```bash
dotnet list package --outdated
```

## 4. Run Existing Tests

If the solution contains a test project, execute the tests to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --verbosity normal
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework APIs and the cross-platform .NET equivalents.

## 5. Check for Platform-Specific Code

Search the codebase for APIs that are known to be Windows-specific or have changed behavior in cross-platform .NET:

- `System.Drawing` (requires `System.Drawing.Common` and may need a compatibility shim on Linux/macOS)
- `Microsoft.Win32.Registry`
- `System.Security.Permissions`
- COM interop or P/Invoke calls targeting Windows DLLs

If any are found and cross-platform support is required, replace them with supported cross-platform alternatives.

## 6. Validate Runtime Behavior

Run the application manually and exercise its primary workflows. Pay attention to:

- File path handling (use `Path.Combine` rather than hardcoded separators)
- Configuration file loading (e.g., `app.config` is not natively supported; migrate to `appsettings.json` with `Microsoft.Extensions.Configuration` if applicable)
- Database connectivity if ADO.NET is in use, ensuring the correct provider packages are referenced

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment target.

## 8. Verify the Published Output

Navigate to the `./publish` directory and confirm:
- The executable and all required assemblies are present.
- Any required configuration files (e.g., `appsettings.json`) are included.
- The application starts and runs correctly from the published output directory.