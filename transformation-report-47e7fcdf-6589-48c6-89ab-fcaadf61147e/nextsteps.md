# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional for multi-targeting.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if they do not block compilation.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and modern .NET (e.g., changes in globalization, threading, or reflection behavior).

### 4. Check for Removed or Changed APIs
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` compatibility tools to identify any API usage that compiles but behaves differently at runtime on modern .NET. Pay particular attention to:

- `System.Web` dependencies (not available on modern .NET)
- `BinaryFormatter` usage (disabled by default in .NET 5+)
- `AppDomain` APIs with reduced functionality
- Windows-specific APIs if cross-platform support is required

### 5. Review NuGet Package Versions
Open the `.csproj` files or a `Directory.Packages.props` file and verify all NuGet packages have versions compatible with the target framework. Run:

```bash
dotnet list package --outdated
```

Update packages where newer versions provide better .NET compatibility.

### 6. Validate Configuration Files
If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or the appropriate modern .NET configuration model, as `System.Configuration.ConfigurationManager` has limited support and behavior differences on modern .NET.

### 7. Smoke Test the Application
Run the application locally and exercise its primary workflows to catch any runtime exceptions that would not surface during compilation or unit testing.

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

### 8. Publish a Release Build
Once validation is complete, produce a published output to confirm the publish pipeline works correctly:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the contents of the `./publish` directory and confirm the application runs from that output folder on a clean machine or environment without the SDK installed (if self-contained deployment is required, add `--self-contained true -r <runtime-identifier>`).