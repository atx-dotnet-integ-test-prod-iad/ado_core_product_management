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

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility analyzers, as these can indicate subtle issues introduced during migration.

## 3. Run Existing Tests

If the solution contains test projects, execute the full test suite:

```bash
dotnet test --configuration Release
```

Review test results carefully. Failures that did not exist prior to migration may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime, such as differences in:

- `System.Text.Encoding` behavior
- Culture-sensitive string comparisons
- File path handling (`Path.DirectorySeparatorChar`)
- Reflection behavior changes

## 4. Verify Platform-Specific Code

Review any code that previously relied on Windows-specific APIs. Common areas to check include:

- Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) usage
- `System.Drawing` (now requires the `System.Drawing.Common` NuGet package on non-Windows platforms)
- COM interop or P/Invoke calls

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package where appropriate.

## 5. Review Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to your intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If cross-platform support is not required and Windows-only APIs are heavily used, consider whether `net8.0-windows` is a more appropriate target.

## 6. Check Configuration and App Settings

If the project previously used `App.config` or `Web.config`, verify that settings have been migrated to `appsettings.json` or environment variables, as `ConfigurationManager` behavior differs in cross-platform .NET. The `Microsoft.Extensions.Configuration` stack is the recommended replacement.

## 7. Validate Runtime Behavior

Run the application manually and exercise its primary workflows. Pay attention to:

- File I/O paths (use `Path.Combine` rather than hardcoded separators)
- Thread culture settings
- Exception handling around APIs that may throw differently on non-Windows platforms

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that includes the .NET runtime:

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (`linux-x64`, `osx-x64`, etc.) for your target environment. A full list of runtime identifiers is available in the [Microsoft RID catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).