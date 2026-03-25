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

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Runtime-Only Issues

Some issues do not surface at build time. Run the application and exercise its primary code paths to check for:

- Reflection-based code that may behave differently on cross-platform .NET
- `System.Configuration` usage that may require migration to `Microsoft.Extensions.Configuration`
- Windows-specific APIs (e.g., registry access, COM interop) that are not available on Linux or macOS

## 5. Review NuGet Package Compatibility

Open the `.csproj` file and review all `<PackageReference>` entries. For each package, confirm it supports your target framework by checking [NuGet.org](https://www.nuget.org). Replace any packages that only target `.NET Framework` with their cross-platform equivalents.

## 6. Validate Platform-Specific Behavior

If the application is intended to run on multiple operating systems, test it explicitly on each target OS. Pay particular attention to:

- File path separators (`\` vs `/`)
- Case sensitivity in file system operations
- Environment variable differences

## 7. Review `app.config` or `web.config` Migrations

If the original project used `app.config` or `web.config`, verify that configuration has been properly migrated to `appsettings.json` and that it is being read correctly at runtime using `Microsoft.Extensions.Configuration`.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required files and dependencies are present. If targeting a specific runtime, include the runtime identifier:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```