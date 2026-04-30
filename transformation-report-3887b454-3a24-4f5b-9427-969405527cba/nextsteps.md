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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Review NuGet Package Versions

Check all `<PackageReference>` entries in `AdoCore.csproj` and any other projects in the solution. Confirm that:

- No packages are pinned to versions targeting `.NET Framework` only.
- Packages have stable, non-prerelease versions unless a prerelease is intentionally required.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify functional correctness after migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences between .NET Framework and modern .NET (e.g., changes in `System.Data`, threading, or serialization behavior).

## 5. Check for Platform-Specific API Usage

Even without build errors, certain APIs may have changed behavior on non-Windows platforms. Review usage of the following areas if cross-platform support is a goal:

- `System.Data` and ADO.NET providers (ensure the correct database driver NuGet package is referenced, such as `Microsoft.Data.SqlClient`).
- File path handling (use `Path.Combine` consistently).
- Registry access or Windows-specific interop calls, which will not function on Linux or macOS.

## 6. Validate Runtime Behavior

Run the application in a local environment and exercise the primary workflows. Pay particular attention to:

- Database connectivity and query execution.
- Any configuration files (migrate `App.config` or `Web.config` values to `appsettings.json` if not already done).
- Logging output for any runtime exceptions that would not surface at compile time.

## 7. Review `appsettings.json` / Configuration

If the project previously relied on `ConfigurationManager`, confirm that configuration has been migrated to the `Microsoft.Extensions.Configuration` pattern, or that the `System.Configuration.ConfigurationManager` NuGet package has been added as a compatibility shim.

## 8. Publish the Application

Once runtime validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the output directory contains all expected binaries and dependencies before deploying to the target environment.