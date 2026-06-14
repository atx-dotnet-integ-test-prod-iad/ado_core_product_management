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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

## 3. Review NuGet Package Versions

Run the following command to check for outdated or vulnerable packages:

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

Update any packages that are flagged, particularly those that were carried over from the legacy project.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any test failures and address them before proceeding.

## 5. Check for Runtime-Specific Code

Search the codebase for any APIs that were available in .NET Framework but behave differently or are unavailable in cross-platform .NET. Common areas to check include:

- `System.Web` references (not available in .NET Core/.NET 5+)
- `AppDomain` usage
- Windows Registry access (`Microsoft.Win32.Registry`)
- `BinaryFormatter` (deprecated and disabled by default in .NET 5+)
- `Thread.Abort()`

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` package where needed.

## 6. Validate Configuration Files

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables, and that `Microsoft.Extensions.Configuration` is being used to read them.

## 7. Test on Target Operating Systems

If cross-platform support is a goal, run the application on each target OS (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear at build time.

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier:

```bash
# Framework-dependent
dotnet publish --configuration Release --output ./publish

# Self-contained for a specific platform
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the contents of the `./publish` directory before deploying to the target environment.