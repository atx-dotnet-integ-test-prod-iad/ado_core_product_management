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

If the solution contains test projects, execute them to verify that behavior has not changed during the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any test failures carefully, as they may indicate runtime behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Runtime Compatibility Issues

Even without build errors, certain APIs behave differently or are unavailable at runtime in cross-platform .NET. Pay particular attention to:

- **Windows-specific APIs**: Any use of `System.Windows.Forms`, `System.Drawing`, or COM interop may require the `<UseWindowsForms>` or `<UseWPF>` flags, or may not function on non-Windows platforms.
- **Registry access**: `Microsoft.Win32.Registry` is Windows-only.
- **Database connectivity**: If `AdoCore` implies ADO.NET usage, verify that the database drivers (e.g., `System.Data.SqlClient` vs `Microsoft.Data.SqlClient`) have been updated to their cross-platform equivalents.

## 5. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` are compatible with your target framework. You can use the following command to identify outdated or incompatible packages:

```bash
dotnet list package --outdated
dotnet list package --deprecated
```

Replace any deprecated or incompatible packages with their recommended alternatives.

## 6. Test on Target Platform

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a Windows-only build.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Or for a self-contained deployment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Adjust the `--runtime` value (`win-x64`, `osx-x64`, etc.) to match your target environment.