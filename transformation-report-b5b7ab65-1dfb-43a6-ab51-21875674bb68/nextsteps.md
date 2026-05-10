# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this aligns with the runtime environment you intend to deploy to.

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

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not cause build failures.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior matches expectations after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether failures are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Runtime Compatibility Issues

Even with a clean build, certain APIs behave differently on cross-platform .NET. Pay attention to the following areas:

- **Windows-specific APIs**: Any use of `System.Windows.Forms`, `System.Drawing`, or COM interop may require the `<UseWindowsForms>` or `<UseWPF>` flags, or may not be available on non-Windows platforms.
- **Registry access**: `Microsoft.Win32.Registry` is Windows-only.
- **File path separators**: Ensure paths use `Path.Combine` or `Path.DirectorySeparatorChar` rather than hardcoded backslashes.
- **Configuration**: If the project previously used `System.Configuration.ConfigurationManager`, confirm the `System.Configuration.ConfigurationManager` NuGet package has been added.

## 5. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` have versions compatible with the target framework. You can use the following command to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions compatible with your target framework.

## 6. Validate Database Connectivity (ADO Specific)

Given the project name `AdoCore`, it likely contains ADO.NET data access logic. Validate the following:

- Connection strings are correctly configured in `appsettings.json` or the appropriate configuration source for .NET.
- Any use of `System.Data.OleDb` is noted as Windows-only; if cross-platform database access is required, consider using a platform-neutral provider.
- Run integration tests or manual queries against a development database to confirm data access operations function correctly.

## 7. Test on Target Platform

If the goal is cross-platform support, run the application on each intended operating system (e.g., Linux, macOS) to surface any platform-specific runtime issues that would not appear during a Windows build.

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
# Framework-dependent deployment
dotnet publish --configuration Release --output ./publish

# Self-contained deployment for a specific platform
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files are present before deploying to the target environment.