# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

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

Ensure there are no warnings that could indicate compatibility issues, such as obsolete API usage or platform-specific code paths.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific Code

Search the codebase for any remaining usage of Windows-specific APIs that may not be available cross-platform. Common areas to check include:

- `Microsoft.Win32` registry access
- `System.Windows.Forms` or `System.Drawing` (GDI+)
- COM interop or P/Invoke calls targeting Windows DLLs
- `AppDomain` usage patterns that have changed in .NET Core and later

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to surface any remaining issues.

## 5. Review NuGet Package Compatibility

Confirm all NuGet dependencies referenced in `AdoCore.csproj` have versions that support the target framework. Run the following to check for outdated or incompatible packages:

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

Replace any packages that do not support your target framework with maintained alternatives.

## 6. Validate Configuration and Connection Strings

If the project uses `App.config` or `Web.config`, verify that configuration has been migrated to `appsettings.json` or environment variables as appropriate for .NET. The `System.Configuration.ConfigurationManager` NuGet package can be used as a compatibility shim if a full migration is not yet feasible.

## 7. Test on Target Platforms

Since the goal is cross-platform support, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time:

```bash
dotnet run --configuration Release
```

Pay particular attention to file path separators, line endings, and case-sensitive file systems when testing on Linux.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
# Framework-dependent deployment
dotnet publish --configuration Release --output ./publish

# Self-contained deployment for a specific platform
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files are present before deploying to the target environment.