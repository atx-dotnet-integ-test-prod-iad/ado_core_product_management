# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility, as these can indicate subtle issues introduced during migration.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests should be investigated to determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Verify Platform-Specific APIs

Review the codebase for any APIs that were available in .NET Framework but may behave differently or be absent in cross-platform .NET. Common areas to check include:

- `System.Windows.Forms` or `System.Web` usage (these are Windows-specific or unavailable)
- Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage
- Remoting or `BinaryFormatter` usage
- `ConfigurationManager` (requires the `System.Configuration.ConfigurationManager` NuGet package)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.ApiCompat` tool to identify any remaining compatibility concerns.

## 5. Review Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If cross-platform support is required, ensure no project is targeting `net8.0-windows` unless Windows-specific APIs are intentionally used.

## 6. Test on Target Operating Systems

If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that do not appear at build time.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier for your deployment target (e.g., `win-x64`, `osx-x64`). Review the publish output directory to confirm all required files are present before deploying.