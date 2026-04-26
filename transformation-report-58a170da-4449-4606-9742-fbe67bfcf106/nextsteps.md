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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

### 4. Check NuGet Package Compatibility
Open each `.csproj` file and review the `<PackageReference>` entries. For any packages that were previously targeting .NET Framework, confirm that compatible versions exist for the new target framework. You can use the following command to check for outdated packages:

```bash
dotnet list package --outdated
```

Update packages where necessary using:

```bash
dotnet add package <PackageName> --version <LatestVersion>
```

### 5. Review Removed or Changed APIs
Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any APIs that were available in .NET Framework but are absent or behave differently in cross-platform .NET. Pay particular attention to:

- `System.Web` usages (not available in .NET Core/.NET 5+)
- `AppDomain` usage
- Windows-specific registry or COM interop calls
- `BinaryFormatter` (deprecated and disabled by default)

### 6. Validate Runtime Behavior on Target Platforms
If cross-platform support (Linux, macOS) is a goal, run the application on each target operating system to surface any platform-specific issues such as:

- File path separator differences (`\` vs `/`)
- Case-sensitive file systems on Linux
- Platform-specific native library dependencies

### 7. Review Output Artifacts
After a successful Release build, inspect the output directory (`bin/Release/net8.0/`) to confirm:

- The expected assemblies are present
- No unnecessary `.pdb` or legacy config files are being carried over
- The `runtimeconfig.json` and `deps.json` files are generated correctly

### 8. Publish the Application
Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime, use:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the published output to confirm all required files are present before deploying to the target environment.