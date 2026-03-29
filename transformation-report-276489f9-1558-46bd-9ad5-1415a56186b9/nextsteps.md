# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version you have installed. Run the following to confirm your SDK version:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support your target framework.

## 3. Build the Solution

Perform a full build in Release configuration to confirm there are no errors or warnings that may have been suppressed during development:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated before proceeding.

## 5. Check for Windows-Specific API Usage

Since this was a legacy project being migrated to cross-platform .NET, scan the codebase for APIs that may only function on Windows. The .NET Compatibility Analyzer can assist with this. You can enable it by adding the following to your `.csproj`:

```xml
<PropertyGroup>
  <PlatformNeutralAssembly>true</PlatformNeutralAssembly>
</PropertyGroup>
```

Common areas to check include:
- `System.Windows.Forms` or `System.Drawing` (GDI+) usage
- Registry access via `Microsoft.Win32.Registry`
- COM interop or P/Invoke calls targeting Windows-only native libraries
- `System.Security.Permissions` types that are no-ops in .NET Core and later

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) to confirm runtime behavior is consistent. Pay particular attention to:

- File path separators (`\` vs `/`)
- Environment variable access
- Culture and encoding differences
- Any configuration files that reference Windows-specific paths

## 7. Review NuGet Package Compatibility

Check that all referenced NuGet packages have versions compatible with your target framework. Visit [nuget.org](https://www.nuget.org) for each dependency and confirm `.NET Standard 2.0` or your specific TFM is listed under supported frameworks.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

**Framework-dependent (requires .NET runtime installed on target machine):**
```bash
dotnet publish --configuration Release
```

**Self-contained (bundles the runtime):**
```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, `osx-arm64`, etc.) as needed.

## 9. Verify Output Artifacts

After publishing, navigate to the output directory (typically `bin/Release/<tfm>/publish/`) and confirm all expected assemblies, configuration files, and static assets are present before deploying to the target environment.