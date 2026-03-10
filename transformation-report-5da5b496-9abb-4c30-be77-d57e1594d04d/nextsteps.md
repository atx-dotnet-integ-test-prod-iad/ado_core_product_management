# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other unintended frameworks.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding.

### 4. Check NuGet Package Compatibility
Review all NuGet dependencies to confirm they support the target framework. You can use the following command to inspect outdated or incompatible packages:

```bash
dotnet list package --outdated
```

Replace any packages that do not have a compatible version with supported alternatives. The [NuGet compatibility page](https://www.nuget.org/packages) and the .NET Upgrade Assistant compatibility analyzer can assist with this.

### 5. Review Removed or Changed APIs
Run the .NET Compatibility Analyzer or inspect the build output for `CA` or `SYSLIB` diagnostic codes that indicate use of obsolete or removed APIs. Pay particular attention to:

- `System.Web` usages (not available in cross-platform .NET)
- Windows-specific APIs (e.g., registry access, WCF server-side, Windows Forms if targeting non-Windows)
- Reflection APIs that changed behavior between .NET Framework and .NET

### 6. Validate Runtime Behavior
Execute the application manually or through integration tests, covering the primary workflows. Confirm that:

- Configuration files (e.g., `appsettings.json` replacing `app.config`/`web.config`) are loading correctly.
- Connection strings and environment-specific settings resolve as expected.
- Logging and dependency injection behave as intended.

### 7. Publish the Application
Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assets, configuration files, and dependencies are present.

### 8. Test the Published Output
Run the published output directly to confirm it functions correctly outside of the development environment:

```bash
dotnet ./publish/AdoCore.dll
```

Or, if a self-contained executable was produced:

```bash
./publish/AdoCore
```

Verify that no missing runtime dependencies or configuration issues surface at this stage.