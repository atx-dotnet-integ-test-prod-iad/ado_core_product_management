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

Review the output for any warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Removed or Changed APIs

Cross-platform .NET removes certain APIs that were available in .NET Framework. Run the .NET Upgrade Assistant compatibility analyzer or the Platform Compatibility Analyzer to surface any runtime-level API issues that do not appear as build errors:

```bash
dotnet tool install -g dotnet-upgrade-assistant
dotnet-upgrade-assistant analyze
```

Pay particular attention to:
- `System.Web` usage
- Windows-specific registry or COM interop calls
- `AppDomain` usage
- `BinaryFormatter` usage (deprecated and disabled by default)

## 5. Review NuGet Package Versions

Open the `.csproj` file and verify that all NuGet package references are targeting versions compatible with your chosen .NET version. Check for any packages that have known replacements or successors on NuGet.org.

## 6. Validate Runtime Behavior

Run the application in a non-production environment and exercise the primary workflows. Confirm that:
- Database connections (if any ADO.NET usage is present, given the `AdoCore` project name) function correctly.
- Connection strings are correctly configured for the new environment.
- Any configuration previously stored in `App.config` or `Web.config` has been migrated to `appsettings.json` or environment variables as appropriate.

## 7. Review Output Artifacts

After a successful Release build, inspect the output directory:

```bash
dotnet publish --configuration Release --output ./publish
```

Confirm that all expected assemblies, configuration files, and dependencies are present in the publish output.

## 8. Smoke Test the Published Output

Run the published output directly to confirm it starts and operates correctly outside of the development environment:

```bash
cd ./publish
dotnet AdoCore.dll
```

Address any runtime exceptions or missing dependency errors that surface at this stage.