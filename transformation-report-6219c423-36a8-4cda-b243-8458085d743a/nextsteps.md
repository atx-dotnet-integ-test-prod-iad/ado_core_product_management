# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

### 2. Restore NuGet Packages
Run the following command from the solution root to ensure all dependencies resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or missing packages.

### 3. Build the Solution
Perform a full build to confirm there are no hidden issues:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that may indicate compatibility concerns even if the build succeeds.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 5. Review Platform-Specific APIs
Search the codebase for any APIs that were available in .NET Framework but have limited or no support in cross-platform .NET. Common areas to check include:

- `System.Web` usage
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage beyond what is supported
- Remoting (`System.Runtime.Remoting`)
- Binary serialization (`BinaryFormatter`)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package to surface any remaining compatibility issues.

### 6. Run the Application
Execute the application directly and exercise its primary workflows to confirm correct runtime behavior:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

### 7. Verify Data Access Behavior
Since the project name suggests ADO.NET usage (`AdoCore`), confirm that all database connection strings, providers, and query behavior function correctly under the new runtime. Pay particular attention to:

- Database provider NuGet packages (e.g., `Microsoft.Data.SqlClient` instead of `System.Data.SqlClient`)
- Connection string formats
- Any platform-specific database drivers

### 8. Check Output Artifacts
Confirm the compiled output is placed in the expected location and that all required assets are included:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to ensure all dependencies and configuration files are present.