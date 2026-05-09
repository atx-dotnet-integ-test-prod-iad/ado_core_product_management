# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this aligns with the runtime environment you intend to deploy to.

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not cause build failures.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior has not changed during the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework APIs and their cross-platform .NET equivalents.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been replaced with stubs or may behave differently on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these issues:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Pay particular attention to areas such as:
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific cryptography
- `System.Drawing` (requires `libgdiplus` on Linux/macOS or migration to an alternative)
- COM interop

## 5. Review NuGet Package Compatibility

Check that all NuGet dependencies reference packages that support your target framework. Run the following to inspect outdated or incompatible packages:

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

Update any packages that have newer versions compatible with your target framework.

## 6. Validate Configuration Files

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or equivalent .NET configuration mechanisms. The legacy XML-based configuration system has limited support in cross-platform .NET.

## 7. Test on Target Operating Systems

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to identify any runtime issues that do not surface during compilation.

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
# Framework-dependent deployment
dotnet publish --configuration Release --output ./publish

# Self-contained deployment for a specific platform
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assets are present before deploying to the target environment.