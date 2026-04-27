# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build context:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or obsolete APIs, as these may indicate areas that need attention.

## 3. Run Existing Tests

If the solution contains test projects, execute the test suite to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated to determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Verify Platform-Specific Code

Inspect the codebase for any APIs that were available in .NET Framework but have changed or been removed in cross-platform .NET. Common areas to check include:

- `System.Web` usages (not available in cross-platform .NET)
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage patterns that differ between runtimes
- WCF server-side components (require `CoreWCF` as a replacement)
- `BinaryFormatter` usage, which is disabled by default in modern .NET

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.ApiCompat` tool to surface any remaining compatibility concerns.

## 5. Test on Target Platforms

Since the project is now cross-platform, validate it runs correctly on each intended operating system (Windows, Linux, macOS) if applicable:

```bash
dotnet run --configuration Release
```

Pay attention to file path separators, environment variable handling, and any OS-specific behavior that may differ.

## 6. Review Target Framework Moniker (TFM)

Open each `.csproj` file and confirm the `<TargetFramework>` value is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If long-term support is a requirement, ensure you are targeting an LTS release of .NET (e.g., .NET 8).

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier for your deployment target. Review the contents of the `publish` output folder to confirm all required assets are present before deploying.