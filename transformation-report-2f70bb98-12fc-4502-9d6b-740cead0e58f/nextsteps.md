# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility, as these can indicate subtle issues introduced during migration.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully. Failures after a migration often point to behavioral differences between .NET Framework and modern .NET, such as changes in reflection, serialization, or threading APIs.

## 4. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure consistency across all projects in the solution, particularly for shared libraries.

## 5. Check for Removed or Changed APIs

Review the code for any usage of APIs that behave differently in modern .NET. Common areas to inspect include:

- `System.Runtime.Serialization` and binary formatters, which have been removed or restricted
- `AppDomain` usage, which has limited support
- `Thread.Abort`, which throws a `PlatformNotSupportedException` in modern .NET
- Any P/Invoke calls that may be platform-specific

The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) can help identify these programmatically.

## 6. Test on Target Platform(s)

Since the goal is cross-platform support, run the application on each intended operating system (Windows, Linux, macOS) and verify that all functionality behaves as expected. Pay particular attention to:

- File path handling (use `Path.Combine` rather than hardcoded separators)
- Case sensitivity in file system operations on Linux
- Platform-specific configuration or registry access

## 7. Review Configuration Files

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or the appropriate modern configuration mechanism. Verify that the configuration is loaded correctly at runtime.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required files and dependencies are present. If a self-contained deployment is needed, add the appropriate runtime identifier:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Adjust the runtime identifier to match your target environment.