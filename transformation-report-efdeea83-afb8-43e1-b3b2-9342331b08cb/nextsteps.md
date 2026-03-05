# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this is consistent with any dependent or consuming projects in the solution.

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

If the solution contains test projects, execute them to verify that runtime behavior has not changed after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Runtime-Only Issues

Some APIs that compiled successfully may behave differently or throw at runtime on cross-platform .NET. Pay particular attention to:

- **Windows-specific APIs**: Features such as the registry, WMI, or certain `System.Drawing` calls may not function on non-Windows platforms without additional NuGet packages (e.g., `Microsoft.Win32.Registry`, `System.Drawing.Common`).
- **ADO.NET providers**: Since the project is named `AdoCore`, verify that any database drivers or providers (e.g., SQL Server, Oracle, OleDb) are explicitly referenced as NuGet packages compatible with .NET Core/5+. `System.Data.OleDb` and similar providers may require platform-specific packages.
- **Configuration**: Confirm that any `App.config` or `Web.config` usage has been replaced or supplemented with `appsettings.json` and `Microsoft.Extensions.Configuration` where appropriate.

## 5. Review NuGet Package Compatibility

Check all NuGet package references in `AdoCore.csproj` to ensure they target .NET Standard 2.0+ or .NET 5/6/7/8 directly. Packages that only target `net45` or similar legacy monikers may still resolve but can cause runtime issues.

```bash
dotnet list package --outdated
```

Update any outdated packages where feasible.

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime failures not caught during the build phase.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) as needed. Review the publish output directory to confirm all required assemblies and configuration files are present before deploying.