# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation

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
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences introduced by the migration to cross-platform .NET.

### 5. Check for Platform-Specific API Usage
Even without build errors, some APIs that compiled successfully may throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code manually for usages of:
- `Microsoft.Win32` registry APIs
- `System.Drawing` (GDI+)
- Windows-specific P/Invoke calls
- `System.Security.Permissions` types

### 6. Run the Application
Execute the application directly and exercise its primary code paths:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Observe runtime output and logs for any exceptions or unexpected behavior.

### 7. Verify Output Artifacts
After a successful Release build, inspect the output directory (typically `bin/Release/net8.0/`) and confirm:
- The expected assemblies are present.
- Any required configuration files (e.g., `appsettings.json`) have been copied to the output directory.
- No legacy `.config` files (e.g., `app.config`, `web.config`) are being relied upon in a way that is incompatible with the new host model.

### 8. Deploy
Once the above steps are validated, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files are present before deploying to the target environment.