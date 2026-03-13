# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

### 2. Restore NuGet Packages
Run the following command from the solution root to ensure all dependencies are restored cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages and consider updating them.

### 3. Build the Solution
Perform a full build to confirm there are no errors:

```bash
dotnet build --configuration Release
```

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review test results carefully, paying attention to any tests that were previously passing on the legacy framework.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any remaining Windows-only API calls (such as those in `System.Drawing`, `System.Windows.Forms`, or the registry) that may compile but fail at runtime on non-Windows platforms.

```bash
dotnet add package Microsoft.DotNet.Compatibility
```

### 6. Review `App.config` / `Web.config` Migrations
If the original project used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or the appropriate .NET configuration provider, as these legacy config files have limited support in cross-platform .NET.

### 7. Validate Runtime Behavior on Target Platforms
Run the application on each platform you intend to support (Windows, Linux, macOS) and verify that core functionality behaves as expected. Pay particular attention to:

- File path separators (`/` vs `\`)
- Case sensitivity in file system operations
- Culture and encoding differences

### 8. Review Output Artifacts
After a successful Release build, inspect the output in the `bin/Release/net8.0/` directory (or whichever target framework was chosen) to confirm all expected assemblies, configuration files, and assets are present.

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of `./publish` to ensure nothing critical is missing before deployment.