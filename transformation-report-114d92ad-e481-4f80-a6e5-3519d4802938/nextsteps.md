# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-specific TFM such as `net472` or `net48`, update it accordingly.

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate compatibility issues, such as platform-specific API usage.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between the old .NET Framework and the new .NET runtime.

## 4. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any APIs that are Windows-only. You can also add the following to your `.csproj` to surface platform compatibility warnings at build time:

```xml
<PropertyGroup>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <AnalysisMode>All</AnalysisMode>
</PropertyGroup>
```

Rebuild after adding these properties and address any new diagnostics.

## 5. Validate NuGet Dependencies

Confirm that all NuGet packages referenced in `AdoCore.csproj` have versions that support your target framework. Run:

```bash
dotnet list package --outdated
```

Update any packages that do not have a compatible version for your target TFM.

## 6. Test on Target Platforms

Since the goal is cross-platform support, run the application or test suite on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time:

```bash
dotnet run --configuration Release
```

Pay particular attention to file path handling, line endings, and any registry or Windows-specific service calls that may have been carried over from the legacy project.

## 7. Review Configuration Files

If the project previously relied on `app.config` or `web.config`, verify that configuration has been migrated to `appsettings.json` or environment variables, as `System.Configuration` support is limited in cross-platform .NET.

## 8. Publish a Release Build

Once validation is complete, produce a published output to confirm the final artifact is correct:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to ensure all required assemblies and assets are present before deploying to the target environment.