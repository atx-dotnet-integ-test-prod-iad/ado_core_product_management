# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as compilation success does not guarantee behavioral correctness after a framework migration.

### 4. Check for Removed or Changed APIs
Some APIs available in .NET Framework are not present or behave differently in cross-platform .NET. Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` compatibility shims if needed. Pay particular attention to:

- `System.Web` usages (not available in cross-platform .NET)
- `AppDomain` APIs with limited support
- Windows-specific registry or COM interop calls
- `BinaryFormatter` (disabled by default in .NET 5+)

### 5. Review NuGet Package Versions
Open the `.csproj` files and verify all NuGet dependencies are referencing versions compatible with your target framework. Run:

```bash
dotnet list package --outdated
```

Update packages where appropriate, and check for any packages that have been superseded by built-in .NET APIs.

### 6. Validate Platform-Specific Behavior
If the project previously ran only on Windows, test it on the target platform(s) to identify any platform-specific runtime failures. Use the [Platform Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to surface potential issues at compile time by adding the following to your `.csproj`:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

### 7. Publish the Application
Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that includes the .NET runtime:

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment target. A full list of runtime identifiers is available in the [Microsoft RID catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).