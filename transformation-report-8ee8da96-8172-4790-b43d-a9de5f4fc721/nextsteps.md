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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Removed or Changed APIs

Cross-platform .NET removes certain APIs that were available in .NET Framework. Run the .NET Upgrade Assistant compatibility analyzer or the platform compatibility analyzer to surface any runtime-level issues that do not appear as build errors:

```bash
dotnet add package Microsoft.DotNet.UpgradeAssistant.Extensions.Default.Analyzers
```

Pay particular attention to:
- `System.Web` usages (not available in .NET Core/.NET 5+)
- Windows-only APIs (e.g., registry access, WinForms, WPF) if cross-platform support is required
- `AppDomain`, `BinaryFormatter`, and other APIs that have been removed or restricted

## 5. Validate NuGet Package Compatibility

Review all NuGet dependencies in `AdoCore.csproj` and confirm each package supports your target framework. You can check compatibility on [nuget.org](https://www.nuget.org) or by inspecting the package's supported frameworks listed in its metadata.

```bash
dotnet list package --outdated
```

Update any outdated packages that have newer versions with proper .NET support.

## 6. Test Runtime Behavior

Build and run the application in a local environment that matches your intended deployment target:

```bash
dotnet run --configuration Release
```

Perform functional testing to confirm the application behaves as expected, particularly around:
- Database connectivity (ADO.NET connection strings and drivers)
- File I/O paths (path separators differ between Windows and Linux/macOS)
- Configuration loading (e.g., `app.config` vs `appsettings.json`)

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment environment. Use `--self-contained true` if you want to bundle the .NET runtime with the output.

## 8. Review Output Artifacts

Inspect the `publish` output directory to confirm all required files, configuration files, and dependencies are present before deploying to the target environment.