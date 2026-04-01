# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other outdated monikers unless intentionally targeting multiple frameworks.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if the build succeeds.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding.

### 4. Check for Removed or Changed APIs
Even with a clean build, some APIs that existed in .NET Framework may behave differently or have been replaced in cross-platform .NET. Review the [.NET Upgrade Assistant compatibility analyzer output](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or use the `Microsoft.DotNet.PlatformAbstractions` and `Microsoft.Windows.Compatibility` NuGet packages if Windows-specific APIs are still required.

### 5. Review NuGet Package Versions
Open each `.csproj` and confirm all `<PackageReference>` entries are pointing to versions that support your target framework. Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update packages where appropriate, particularly any that were previously targeting .NET Framework.

### 6. Validate Platform-Specific Code
Search the solution for any usage of:
- `System.Windows.Forms`
- `System.Web`
- `Microsoft.Win32` registry APIs
- P/Invoke calls or native interop

These areas may compile successfully but fail at runtime on non-Windows platforms. Conditionally compile or replace them as needed.

### 7. Run the Application
Execute the application directly to confirm it starts and behaves as expected:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Test all major functional areas manually or through integration tests.

## Deployment Steps

### 1. Publish a Self-Contained or Framework-Dependent Build
Choose the appropriate publish mode for your deployment target.

**Framework-dependent (smaller output, requires .NET runtime on host):**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (larger output, no runtime dependency on host):**
```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) for your target platform.

### 2. Verify Published Output
Navigate to the `./publish` directory and confirm all expected assemblies, configuration files, and assets are present before deploying to the target environment.

### 3. Test in the Target Environment
Deploy the published output to a staging environment that mirrors production and run a full functional verification before promoting to production.