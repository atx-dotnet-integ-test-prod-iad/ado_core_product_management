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

Address any failing tests before proceeding further.

### 4. Check for Removed or Changed APIs
Use the .NET Upgrade Assistant compatibility analyzer or review the [.NET API compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) to identify any APIs that were available in .NET Framework but behave differently or are absent in cross-platform .NET. Pay particular attention to:

- `System.Web` usages (not available in .NET Core+)
- Windows-specific APIs (e.g., registry access, WCF server-side, Windows Forms if targeting non-Windows)
- `AppDomain`, `Remoting`, or `BinaryFormatter` usages

### 5. Review NuGet Package Versions
Open the `.csproj` files and verify all NuGet package references are up to date and compatible with the target framework:

```bash
dotnet list package --outdated
```

Update packages where necessary, particularly any that were previously targeting .NET Framework-specific builds.

### 6. Validate Platform-Specific Behavior
If the application uses file paths, line endings, or OS-specific features, test the application on each intended target platform (Windows, Linux, macOS) to surface any platform-specific runtime issues.

### 7. Review Output Artifacts
After a successful Release build, inspect the output directory (`bin/Release/net8.0/` or equivalent) to confirm:

- The correct runtime files are present.
- No unexpected `.dll` files from old .NET Framework dependencies remain.
- The application executable or library is present and correctly named.

### 8. Perform Smoke Testing
Run the application manually or through a defined test plan to verify core functionality behaves as expected under the new runtime. Focus on entry points, configuration loading, and any external integrations (databases, file I/O, network calls).

### 9. Publish the Application
Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate RID (e.g., `linux-x64`, `osx-x64`) based on your deployment target. Review the published output before deploying to the target environment.