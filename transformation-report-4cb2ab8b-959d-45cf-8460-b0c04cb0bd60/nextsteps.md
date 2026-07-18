# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation

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

Review the output for any warnings about deprecated packages or packages that could not be resolved.

### 3. Build the Solution
Perform a full build to confirm there are no errors:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as failures may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any APIs that are Windows-specific and may not behave correctly on Linux or macOS:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to areas such as:
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific cryptography providers
- `System.Drawing` (GDI+ backed)
- COM interop

### 6. Review `App.config` / `Web.config` Migrations
If the original project used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or equivalent .NET configuration providers where applicable.

### 7. Verify Output Artifacts
After a successful Release build, inspect the output directory (`bin/Release/net8.0/` or equivalent) to confirm:
- The expected assemblies are present.
- No unintended dependencies on `.dll` files from the legacy GAC or framework directories exist.

## Deployment

### 1. Publish the Application
Use the `dotnet publish` command to produce deployment-ready output:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require .NET to be installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier for your target platform (e.g., `linux-x64`, `osx-x64`).

### 2. Verify Published Output
Run the published output on the target machine or environment to confirm the application starts and operates correctly:

```bash
./publish/AdoCore
```

### 3. Review Assembly Versioning
Confirm that `AssemblyInfo.cs` attributes or `<Version>`, `<AssemblyVersion>`, and `<FileVersion>` properties in the `.csproj` are set correctly before distributing the build.