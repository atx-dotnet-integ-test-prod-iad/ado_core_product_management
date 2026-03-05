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

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate runtime behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Runtime Compatibility Issues

Even with a clean build, certain APIs behave differently or are unavailable at runtime on cross-platform .NET. Pay particular attention to:

- **Windows-specific APIs**: Any usage of `System.Windows.Forms`, `System.Drawing`, or COM interop may require the `<UseWindowsForms>` or `<UseWPF>` flags, or may not function on non-Windows platforms.
- **Registry access**: `Microsoft.Win32.Registry` is Windows-only.
- **Database connectivity**: If `AdoCore` implies ADO.NET usage, verify that the database drivers (e.g., `System.Data.SqlClient` vs `Microsoft.Data.SqlClient`) are the current recommended packages.

## 5. Review NuGet Package Versions

Check that all NuGet dependencies are up to date and compatible with your target framework:

```bash
dotnet list package --outdated
```

Replace any packages that have known incompatibilities or that have been superseded by newer alternatives (e.g., `System.Data.SqlClient` should be replaced with `Microsoft.Data.SqlClient`).

## 6. Validate Configuration Files

Ensure that any `App.config` or `Web.config` files have been properly migrated to `appsettings.json` or environment-based configuration using `Microsoft.Extensions.Configuration`. Legacy XML-based configuration is not natively supported in cross-platform .NET.

## 7. Test on Target Platform

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a Windows-only build.

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) as needed. Use `--self-contained true` if you require the .NET runtime to be bundled with the output.