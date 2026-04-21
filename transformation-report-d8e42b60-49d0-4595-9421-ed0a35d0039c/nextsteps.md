# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

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

Review the output for any warnings that may indicate deprecated APIs or compatibility issues that did not surface as hard errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations from the legacy project:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any test failures by reviewing logic that may have been affected by differences between .NET Framework and cross-platform .NET (e.g., `System.Data`, `System.Drawing`, file path handling, or culture-sensitive operations).

## 4. Check for Runtime Compatibility Issues

Even with a clean build, certain APIs behave differently on cross-platform .NET. Review the following areas manually:

- **Database access**: If `AdoCore` implies ADO.NET usage, verify that the database drivers (e.g., `Microsoft.Data.SqlClient`) are compatible and properly referenced as NuGet packages.
- **File I/O**: Replace any hardcoded Windows-style paths (`C:\...`) with `Path.Combine` or `Path.DirectorySeparatorChar`.
- **Registry access**: `Microsoft.Win32.Registry` is not supported on Linux/macOS. Remove or conditionally compile any registry-dependent code.
- **Configuration**: Ensure `app.config` or `web.config` usage has been migrated to `appsettings.json` and `Microsoft.Extensions.Configuration` where applicable.

## 5. Analyze NuGet Package Compatibility

Run the following command to check for any packages that may not fully support your target framework:

```bash
dotnet list package --outdated
dotnet list package --deprecated
```

Update any outdated or deprecated packages to versions that explicitly support your target framework.

## 6. Use the .NET Upgrade Assistant for Final Verification

If not already done, run the [.NET Upgrade Assistant](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) in analysis mode to catch any remaining compatibility concerns:

```bash
upgrade-assistant analyze AdoCore.csproj
```

Review the generated report for any flagged APIs or patterns.

## 7. Test on Target Platform

If the goal is cross-platform support, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a Windows-only build.

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
# Framework-dependent (requires .NET runtime on target machine)
dotnet publish --configuration Release --output ./publish

# Self-contained (bundles the runtime)
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Verify the contents of the `./publish` directory and confirm the application runs correctly from that output.