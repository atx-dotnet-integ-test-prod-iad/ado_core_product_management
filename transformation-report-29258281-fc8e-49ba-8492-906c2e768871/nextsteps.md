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

If the solution contains test projects, execute them to verify runtime behavior has not changed after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any test failures carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Runtime Compatibility Issues

Even with a clean build, certain APIs behave differently on cross-platform .NET. Review the following areas manually:

- **Registry access**: `Microsoft.Win32.Registry` is Windows-only. Wrap usages with runtime OS checks if cross-platform support is required.
- **Windows-specific APIs**: Any P/Invoke calls or use of `System.Drawing`, `System.Windows.Forms`, or COM interop should be audited.
- **Configuration**: Ensure any `app.config` or `web.config` reliance has been migrated to `appsettings.json` or `IConfiguration` equivalents.
- **ADO.NET providers**: Since the project is named `AdoCore`, confirm that the database provider NuGet packages (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, etc.) are the cross-platform compatible versions.

## 5. Review NuGet Package Versions

Open the `.csproj` file and verify all NuGet packages are up to date and compatible with your target framework. You can check for outdated packages with:

```bash
dotnet list package --outdated
```

Update packages where appropriate, particularly any that were carried over from the legacy project and may have newer cross-platform compatible versions available.

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application or test suite on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a build.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
# Framework-dependent (requires .NET runtime on target machine)
dotnet publish --configuration Release --output ./publish

# Self-contained (includes runtime in output)
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Review the contents of the `./publish` directory to confirm all expected files are present before deploying to the target environment.