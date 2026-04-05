# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this aligns with the runtime version installed on your machine.

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore NuGet Packages

Run the following command from the solution root to ensure all dependencies are restored cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages that may need to be updated.

## 3. Build the Solution

Perform a full build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility that surface during the build.

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite to verify that existing functionality behaves as expected after the migration:

```bash
dotnet test --configuration Release
```

Review any failing tests and determine whether the failures are due to behavioral differences in the new .NET runtime or pre-existing issues.

## 5. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any APIs that may behave differently or are unavailable on non-Windows platforms. Run the following if the analyzer is available:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

Pay particular attention to:
- `System.Windows.Forms` or `System.Drawing` usage
- Registry access (`Microsoft.Win32.Registry`)
- COM interop
- P/Invoke calls targeting Windows-specific native libraries

## 6. Validate Runtime Behavior

Run the application and exercise its primary workflows manually to confirm that runtime behavior matches the legacy version. Compare outputs, data access results, and any file or network operations against the original application.

## 7. Review `app.config` / `web.config` Migration

If the original project used `app.config` or `web.config`, verify that settings have been correctly migrated to `appsettings.json` or the appropriate .NET configuration provider. Confirm that connection strings, application settings, and environment-specific values are loading correctly.

## 8. Publish the Application

Once validation is complete, publish the application using the following command, adjusting the runtime identifier (`-r`) as needed for your target platform:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment:

```bash
dotnet publish --configuration Release -r win-x64 --self-contained true --output ./publish
```

Verify the contents of the `./publish` directory and confirm the application runs correctly from that location before distributing it.