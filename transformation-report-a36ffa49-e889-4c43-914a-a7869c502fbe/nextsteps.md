# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other end-of-life targets unless intentional.

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

Review any failing tests and address them before proceeding.

### 4. Check for Removed or Changed APIs
Use the .NET Upgrade Assistant compatibility analyzer or review the [.NET API compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) to identify any APIs that were available in .NET Framework but have changed behavior or been removed in modern .NET. Pay particular attention to:

- `System.Web` usages (not available in cross-platform .NET)
- Windows-only APIs (e.g., registry access, WCF server-side, certain `System.Drawing` features)
- Reflection APIs that have changed behavior

### 5. Audit NuGet Package Versions
Open the `.csproj` files or a `Directory.Packages.props` file and verify all NuGet packages are referencing versions compatible with your target framework. Run:

```bash
dotnet list package --outdated
```

Update packages that have newer stable versions compatible with your target framework.

### 6. Review Platform-Specific Code
Search the solution for conditional compilation symbols such as `#if NET48` or `#if NETFRAMEWORK` to ensure any platform-specific code paths are still correct and that cross-platform paths are exercised properly.

### 7. Perform Runtime Smoke Testing
Run the application locally and exercise the primary workflows to confirm runtime behavior is correct. Build errors alone do not guarantee runtime correctness, particularly around:

- Configuration loading (`appsettings.json` vs. `App.config`/`Web.config`)
- Dependency injection registrations
- File path handling (ensure `Path.Combine` is used rather than hardcoded backslashes)
- Serialization behavior changes between .NET Framework and modern .NET

### 8. Publish a Release Build
Once validation passes, produce a self-contained or framework-dependent publish artifact:

```bash
# Framework-dependent
dotnet publish --configuration Release --output ./publish

# Self-contained (example for Linux x64)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the output in the `./publish` directory runs correctly on the intended target platform.