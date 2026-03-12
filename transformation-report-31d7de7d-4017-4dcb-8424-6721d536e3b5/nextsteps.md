# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to the intended cross-platform .NET version (e.g., `net6.0`, `net7.0`, or `net8.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If the TFM does not match your intended runtime, update it accordingly and rebuild.

## 2. Restore Dependencies

Run a full NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts and update them in the `.csproj` file as needed.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet clean
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or obsolete API usage.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences in the new runtime or by incomplete migration of dependencies.

## 5. Check for Removed or Changed APIs

Cross-platform .NET removed several APIs that were available in .NET Framework. Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any runtime-level incompatibilities that do not surface as build errors:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to:
- `System.Web` usage (not available in cross-platform .NET)
- Windows-specific registry or file path APIs
- `AppDomain` usage that relied on .NET Framework behavior
- Reflection APIs that have changed behavior

## 6. Test on Target Platform(s)

If the goal is cross-platform support, run the application on each intended operating system (Windows, Linux, macOS) to identify any platform-specific runtime issues:

```bash
dotnet run --configuration Release
```

Look for exceptions related to file path separators, platform-specific encoding defaults, or missing native dependencies.

## 7. Review Configuration Files

Ensure that any configuration previously handled by `app.config` or `web.config` has been migrated to the appropriate cross-platform equivalent:

- Use `appsettings.json` with `Microsoft.Extensions.Configuration` for application settings.
- Verify connection strings and environment-specific values are correctly defined.

## 8. Validate NuGet Package Compatibility

Check that all referenced NuGet packages support the target framework. Packages that only target `net45` or similar legacy monikers may have compatibility shims but could behave differently at runtime. Visit [nuget.org](https://www.nuget.org) or use:

```bash
dotnet list package --outdated
```

Update packages where newer versions provide native cross-platform support.

## 9. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier (RID) for your deployment target (e.g., `win-x64`, `osx-x64`). Review the output directory to confirm all required files are present.