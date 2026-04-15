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

If the solution contains test projects, execute them to verify runtime behavior has not changed after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Runtime-Only Issues

Some issues do not surface at build time. Pay attention to the following areas that commonly differ between .NET Framework and modern .NET:

- **`System.Configuration`**: `ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package on modern .NET.
- **WCF or Remoting**: These are not fully supported on cross-platform .NET. Verify no such dependencies exist.
- **`AppDomain`**: Some `AppDomain` APIs are no-ops or throw `PlatformNotSupportedException` on modern .NET.
- **Registry access**: `Microsoft.Win32.Registry` is Windows-only. If cross-platform support is required, this must be abstracted.
- **`System.Drawing`**: Requires the `System.Drawing.Common` package and may have platform restrictions.

## 5. Review NuGet Package Compatibility

Open the `.csproj` file and review all `<PackageReference>` entries. For each package, confirm the version being referenced supports your target framework. Use [NuGet.org](https://www.nuget.org) to check compatibility if needed.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

**Framework-dependent (requires .NET runtime installed on host):**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (bundles the runtime):**
```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) as needed.

## 8. Validate the Published Output

Navigate to the `./publish` directory and run the output directly to confirm the published artifact behaves as expected before deploying to the target environment.