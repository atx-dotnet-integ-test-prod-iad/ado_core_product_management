# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net4x` or `netstandard` targets unless explicitly required.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if they do not produce build errors.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 4. Check for Removed or Unsupported APIs
Even with a successful build, some APIs behave differently or have been removed in cross-platform .NET. Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.ApiCompat` tooling to surface any potential runtime incompatibilities:

```bash
dotnet tool install -g dotnet-apicompat
```

Pay particular attention to:
- `System.Web` usages (not available on cross-platform .NET)
- Windows-only APIs (e.g., registry access, WCF server-side, Windows-specific P/Invoke calls)
- `BinaryFormatter` (disabled by default in .NET 5+)
- `AppDomain` APIs with limited support

### 5. Review NuGet Package Versions
Open the `.csproj` files and verify that all NuGet package references are up to date and compatible with your target framework. You can check for outdated packages with:

```bash
dotnet list package --outdated
```

Replace any packages that target only `net4x` with their cross-platform equivalents where available.

### 6. Validate Configuration Files
If the project previously used `app.config` or `web.config`, confirm that configuration has been migrated to `appsettings.json` or environment-based configuration as appropriate for the new hosting model.

### 7. Smoke Test Core Functionality
Run the application locally and exercise its primary workflows manually or through integration tests to confirm that the core business logic behaves as expected under the new runtime.

### 8. Publish the Application
Once validation is complete, produce a release build artifact using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment (no runtime dependency on the target machine):

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment target. A full list of runtime identifiers is available in the [Microsoft RID catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).

### 9. Verify Output on Target Environment
Deploy the published output to a staging environment that mirrors production and run the same validation steps performed locally to confirm there are no environment-specific issues.