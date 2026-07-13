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

Verify that no warnings are promoted to errors and that all projects report a successful build.

## 3. Run Existing Tests

If the solution contains any test projects, execute them to confirm that existing behavior has been preserved after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review the output for any failing tests and address them before proceeding.

## 4. Check for Removed or Changed APIs

Cross-platform .NET removes or modifies certain APIs that were available in .NET Framework. Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` compatibility tooling to scan for any runtime-level API incompatibilities that would not surface as build errors:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <solution>.sln
```

## 5. Validate NuGet Package Compatibility

Open the `.csproj` file and review all `<PackageReference>` entries. Confirm that each package version supports your target framework. Packages that targeted `.NET Framework` only may require updates or replacements. Check compatibility on [NuGet.org](https://www.nuget.org).

## 6. Test Platform-Specific Behavior

If `AdoCore` interacts with any of the following, manual testing is required to confirm correct behavior on the target platform:

- File system paths (directory separators differ between Windows and Linux/macOS)
- Registry access (not available on Linux/macOS)
- Windows-specific authentication or identity APIs
- COM interop or P/Invoke calls

## 7. Run the Application

Execute the application directly to observe runtime behavior:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Or, if this is a library, reference it from a test harness or consuming application and exercise its primary code paths.

## 8. Publish the Application

Once validation is complete, publish the application for your target environment:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment target.

## 9. Review Output Artifacts

Inspect the contents of the `./publish` directory to confirm all expected assemblies, configuration files, and dependencies are present before deploying to the target environment.