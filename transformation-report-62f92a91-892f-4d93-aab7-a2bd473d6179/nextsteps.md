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

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not block the build.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior has not changed after migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework APIs and their cross-platform equivalents.

## 4. Check for Runtime-Only Issues

Some issues do not surface at build time but appear at runtime. Pay particular attention to the following areas:

- **File system paths**: Ensure no hardcoded Windows-style paths (e.g., `C:\`) exist in configuration or code.
- **Registry access**: `Microsoft.Win32.Registry` is not supported on Linux/macOS. Replace any registry-dependent logic with configuration file alternatives.
- **Windows-specific APIs**: Review any P/Invoke calls or use of `System.Windows.Forms` / `System.Drawing` that may not be supported cross-platform.
- **Configuration files**: Verify that `app.config` or `web.config` settings have been migrated to `appsettings.json` or environment variables where applicable.

## 5. Review NuGet Package Compatibility

Check that all NuGet dependencies are compatible with your target framework. Run the following to identify any outdated packages:

```bash
dotnet list package --outdated
```

Additionally, run the compatibility check:

```bash
dotnet list package --vulnerable
```

Replace or update any packages that are flagged as incompatible or vulnerable.

## 6. Test on the Target Platform

If the goal is cross-platform support, run the application on each target operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues not caught during local development.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with your intended runtime identifier (e.g., `win-x64`, `osx-x64`). Use `--self-contained true` if you need to bundle the .NET runtime with the output.

## 8. Verify Published Output

After publishing, navigate to the output directory and confirm that all expected assemblies, configuration files, and static assets are present before deploying to the target environment.