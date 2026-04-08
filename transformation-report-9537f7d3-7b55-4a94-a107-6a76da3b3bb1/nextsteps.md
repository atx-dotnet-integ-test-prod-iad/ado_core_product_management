# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build context:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types or obsolete APIs, as these may indicate areas that could cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during the migration:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests should be investigated to determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Verify Platform-Specific API Usage

Review the codebase for any APIs that were available in .NET Framework but have changed or are unavailable in cross-platform .NET. Common areas to check include:

- `System.Web` references (not available in .NET Core/.NET 5+)
- Windows Registry access (`Microsoft.Win32.Registry`)
- WCF server-side components
- `AppDomain` usage
- Remoting APIs
- `BinaryFormatter` (deprecated and disabled by default)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.ApiCompat` tool to identify any remaining compatibility concerns.

## 5. Test on Target Platforms

Since the goal is cross-platform support, run and validate the application on each intended target operating system (e.g., Windows, Linux, macOS):

```bash
dotnet run --configuration Release
```

Pay attention to:
- File path separator differences (`/` vs `\`)
- Case sensitivity in file system access (Linux is case-sensitive)
- Environment variable differences across operating systems

## 6. Review Target Framework Moniker (TFM)

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If you require Windows-specific APIs in certain projects, ensure those projects use:

```xml
<TargetFramework>net8.0-windows</TargetFramework>
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier for your deployment target (e.g., `win-x64`, `osx-x64`). Review the output directory to confirm all required files are present.