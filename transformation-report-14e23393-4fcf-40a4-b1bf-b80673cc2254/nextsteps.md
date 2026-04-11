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

If the solution contains test projects, execute them to verify that runtime behavior matches expectations after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding further.

## 4. Check for Runtime-Only Issues

Some issues do not surface at build time. Run the application and exercise its primary code paths to check for:

- Missing configuration files (e.g., `appsettings.json`)
- APIs that were removed or behave differently in modern .NET (e.g., `System.Web`, `BinaryFormatter`, certain reflection APIs)
- Platform-specific behavior differences if the application is now running on Linux or macOS

## 5. Review NuGet Package Compatibility

Open the `.csproj` file and review all `<PackageReference>` entries. Confirm that each package version is compatible with your target framework. Use the following command to check for outdated packages:

```bash
dotnet list package --outdated
```

Update packages where newer, compatible versions are available.

## 6. Review Removed or Changed .NET APIs

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for usage of APIs that have been removed or altered in modern .NET. This is particularly relevant if the original project targeted .NET Framework.

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <solution>.sln
```

## 7. Validate Output Artifacts

After a successful Release build, inspect the output directory (typically `bin/Release/net8.0/`) to confirm:

- The expected assemblies and dependencies are present
- No legacy `.config` files are being relied upon that should have been replaced by `appsettings.json` or environment variables

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory and confirm all required files are present before deploying to the target environment.