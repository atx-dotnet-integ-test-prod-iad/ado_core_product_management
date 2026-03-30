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

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm there are no warnings that may indicate runtime issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify functional correctness after the migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee correct runtime behavior.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer or the following command to scan for platform-specific API calls that may not behave correctly on Linux or macOS:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to any `CA1416` warnings, which flag Windows-only APIs.

### 6. Run the Application
Execute the application directly to observe runtime behavior:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Test all major code paths, particularly any that involve file I/O, database connections, or network calls, as these areas are most likely to surface cross-platform issues at runtime.

### 7. Review NuGet Package Compatibility
Check that all third-party NuGet packages in use have builds targeting .NET Standard 2.0+ or the specific .NET version you are targeting. Packages that only ship `net45` or `net48` targets may still resolve but can cause runtime failures.

You can inspect package compatibility at [https://www.nuget.org](https://www.nuget.org) or by reviewing the `lib` folders inside the `.nupkg` files in your local NuGet cache.

### 8. Validate Configuration Files
If the project previously used `App.config` or `Web.config`, confirm that any necessary settings have been migrated to `appsettings.json` or equivalent .NET configuration providers, as `System.Configuration` support is limited in cross-platform .NET.