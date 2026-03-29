# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other outdated monikers unless intentionally targeting multiple frameworks.

### 2. Restore and Build Locally
Run the following commands from the root of the solution to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding further.

### 4. Check for Removed or Changed APIs
Use the [.NET Upgrade Assistant](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.ApiCompat` tooling to identify any APIs that were available in .NET Framework but have changed behavior or are absent in cross-platform .NET.

Pay particular attention to:
- `System.Web` usages (not available in cross-platform .NET)
- Windows-specific APIs (e.g., registry access, WCF server-side, Windows Forms if targeting non-Windows)
- `AppDomain`, `BinaryFormatter`, and `Remoting` APIs

### 5. Audit NuGet Package Versions
Open the solution in Visual Studio or run the following command to check for outdated or vulnerable packages:

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

Update packages where appropriate, and replace any packages that were targeting .NET Framework exclusively with their cross-platform equivalents.

### 6. Validate Platform-Specific Behavior
If the application relies on any platform-specific functionality, test it explicitly on each intended target platform (Windows, Linux, macOS) to confirm consistent behavior.

### 7. Review Configuration Files
Confirm that any configuration previously handled by `app.config` or `web.config` has been properly migrated to `appsettings.json` or environment-based configuration using `Microsoft.Extensions.Configuration`.

### 8. Publish the Application
Once the build and tests are passing, produce a published output to verify the deployment artifact is correct:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to ensure all required assemblies, configuration files, and assets are present.

### 9. Smoke Test the Published Output
Run the published output directly to confirm the application starts and operates correctly outside of the development environment:

```bash
cd ./publish
dotnet AdoCore.dll
```

Replace `AdoCore.dll` with the appropriate entry point assembly if the project is not the startup project.