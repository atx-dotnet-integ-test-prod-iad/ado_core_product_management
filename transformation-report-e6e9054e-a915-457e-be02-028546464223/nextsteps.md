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

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Pay attention to any test failures that may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Runtime Compatibility Issues

Even with a clean build, certain APIs behave differently on cross-platform .NET. Review the following areas manually:

- **Registry access**: `Microsoft.Win32.Registry` is Windows-only. If `AdoCore` uses registry reads/writes, those code paths will fail on Linux/macOS.
- **Windows-specific APIs**: Check for usage of `System.Drawing`, `System.Windows.Forms`, or COM interop, as these are not fully supported cross-platform.
- **Database connectivity**: If the project uses ADO.NET with a specific database provider (e.g., `System.Data.OleDb`), confirm the provider is supported on your target OS.
- **Configuration**: Ensure any `App.config` or `Web.config` settings have been migrated to `appsettings.json` or environment variables where applicable.

## 5. Review NuGet Package Compatibility

Open the `.csproj` file and review all `<PackageReference>` entries. For each package, confirm it targets `.NET Standard 2.0` or higher, or has a specific `net6.0`/`net8.0` compatible version. You can use the following command to check for outdated packages:

```bash
dotnet list package --outdated
```

Update packages where necessary:

```bash
dotnet add package <PackageName> --version <NewVersion>
```

## 6. Test on Target Operating System

If cross-platform support is a goal, run the application on each target OS (Windows, Linux, macOS) and exercise all major code paths. Pay particular attention to file path handling, as `\` vs `/` differences can cause runtime errors that do not appear at build time.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate RID (e.g., `linux-x64`, `osx-x64`) as needed. Review the output in the `publish` folder before deploying to the target environment.