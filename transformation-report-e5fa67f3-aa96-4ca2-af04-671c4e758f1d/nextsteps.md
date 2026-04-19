# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command in the root of your solution to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or obsolete APIs, as these may indicate areas of the code that could cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute the full test suite to verify that behavior has not changed during the migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully. Failures may indicate behavioral differences between the legacy .NET Framework APIs and their cross-platform .NET equivalents.

## 4. Verify Target Framework

Open each `.csproj` file and confirm that the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure consistency across all projects in the solution to avoid inter-project compatibility issues.

## 5. Check for Platform-Specific API Usage

Review the code for any APIs that were available in .NET Framework but have limited or no support in cross-platform .NET. Common areas to inspect include:

- `System.Windows.Forms` or `System.Web` usage
- Registry access via `Microsoft.Win32`
- `AppDomain` usage
- `BinaryFormatter` serialization, which is disabled by default in modern .NET

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining incompatibilities.

## 6. Review Configuration Files

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to the appropriate modern equivalents:

- Use `appsettings.json` for application configuration
- Use `Microsoft.Extensions.Configuration` for reading configuration values at runtime

## 7. Test on Target Platforms

Since the goal of the migration is cross-platform support, run and validate the application on each intended target operating system (e.g., Windows, Linux, macOS):

```bash
dotnet run --configuration Release
```

Pay close attention to file path handling, line endings, and any OS-specific behavior in the existing code.

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier for your deployment target. A full list of runtime identifiers is available in the [Microsoft documentation](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).