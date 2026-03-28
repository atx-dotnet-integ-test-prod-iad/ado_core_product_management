# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other Windows-only framework monikers unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Resolve any warnings about deprecated or incompatible packages before proceeding.

### 3. Build the Solution
Perform a full build to confirm there are no warnings that could indicate runtime issues:

```bash
dotnet build --configuration Release
```

Review any remaining warnings, particularly those related to nullable reference types, platform compatibility (`CA1416`), or obsolete APIs.

### 4. Run the Test Suite
If the solution contains test projects, execute them to validate functional correctness:

```bash
dotnet test --configuration Release --logger trx
```

Review the output for any failing tests that may indicate behavioral differences introduced during the migration.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer or the following CLI tool to identify any remaining platform-specific API calls that may fail on non-Windows operating systems:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Pay particular attention to usages of `System.Windows.Forms`, `System.Drawing`, `Microsoft.Win32`, or P/Invoke calls targeting Windows-only libraries.

### 6. Verify Runtime Behavior on Target Platforms
Run the application on each platform you intend to support (Linux, macOS, Windows) and confirm that file paths, line endings, environment variables, and culture-sensitive operations behave as expected.

```bash
dotnet run --configuration Release
```

### 7. Review `app.config` / `web.config` Migrations
If the original project used `app.config` or `web.config`, confirm that settings have been correctly migrated to `appsettings.json` or equivalent .NET configuration providers, and that they are being read correctly at runtime.

### 8. Publish the Application
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) for your deployment target. Review the output directory to confirm all required files are present.