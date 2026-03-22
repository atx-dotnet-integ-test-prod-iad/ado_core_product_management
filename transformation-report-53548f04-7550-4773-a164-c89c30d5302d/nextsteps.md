# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). For example:

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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Runtime Compatibility Issues

Even with a clean build, certain APIs behave differently on cross-platform .NET compared to .NET Framework. Pay particular attention to:

- **Windows-specific APIs**: Any use of `System.Windows.Forms`, `System.Drawing`, or COM interop may require the `<UseWindowsForms>` or `<UseWPF>` flags, or may not be available on non-Windows platforms.
- **Registry access**: `Microsoft.Win32.Registry` is Windows-only.
- **File path separators**: Ensure paths use `Path.Combine` or `Path.DirectorySeparatorChar` rather than hardcoded backslashes.
- **Database connectivity**: If the project uses ADO.NET (suggested by the project name `AdoCore`), verify that the database drivers (e.g., `Microsoft.Data.SqlClient`, `Npgsql`) are referencing the correct cross-platform NuGet packages.

## 5. Review NuGet Package Versions

Open the `.csproj` file and check that all NuGet package references are up to date and compatible with your target framework:

```bash
dotnet list package --outdated
```

Update packages where appropriate, and check for any packages that have known replacements for cross-platform .NET (e.g., replacing `System.Data.SqlClient` with `Microsoft.Data.SqlClient`).

## 6. Run on Target Platform

If the goal is cross-platform support, test the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime exceptions that would not appear during a build.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# Framework-dependent (requires .NET runtime installed on target machine)
dotnet publish --configuration Release --output ./publish

# Self-contained (bundles the runtime)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all expected files are present before deploying to the target environment.