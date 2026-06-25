# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

### 2. Restore Dependencies
Run a NuGet restore to ensure all packages resolve correctly against the new target framework:

```bash
dotnet restore
```

Review the output for any dependency conflicts or packages that could not be resolved.

### 3. Build the Solution
Perform a full solution build to confirm there are no errors:

```bash
dotnet build --configuration Release
```

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify that existing behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review the test output and address any failing tests before proceeding.

### 5. Review Removed or Replaced APIs
Check any code that previously relied on Windows-only or .NET Framework-specific APIs. Common areas to review include:

- `System.Web` usages (not available in .NET Core/.NET 5+)
- `AppDomain` usage patterns that differ in modern .NET
- `BinaryFormatter` (deprecated and disabled by default)
- Registry access or Windows-specific interop

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining platform-specific calls.

### 6. Check Runtime Behavior
Even without build errors, runtime behavior should be validated:

- Exercise all major code paths manually or through integration tests.
- Verify configuration loading (e.g., `app.config` vs `appsettings.json` if applicable).
- Confirm file path handling is cross-platform (use `Path.Combine` rather than hardcoded separators).

### 7. Publish the Application
Once validation is complete, publish the application for your target platform:

**Framework-dependent (requires .NET runtime on target machine):**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (bundles the runtime):**
```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment target. A full list of runtime identifiers is available in the [Microsoft RID catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).