# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-only TFM such as `net472` or `net48`, update it accordingly.

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate compatibility issues that were not surfaced as hard errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address regressions introduced by the migration.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been silently replaced or may behave differently on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
dotnet build
```

Pay attention to any `CA1416` (platform compatibility) warnings in the build output.

## 5. Review NuGet Package Versions

Open the `.csproj` file and review all `<PackageReference>` entries. Ensure that:

- No packages are pinned to versions that only support .NET Framework.
- Packages have been updated to their latest stable versions that support the target TFM.

You can check for outdated packages with:

```bash
dotnet list package --outdated
```

## 6. Validate Runtime Behavior on Target Platforms

Run the application on each platform you intend to support (Windows, Linux, macOS) and verify that:

- File path handling uses `Path.Combine` rather than hardcoded separators.
- Any registry, COM interop, or Windows-specific calls have been removed or conditionally compiled.
- Configuration files and environment variables are loaded correctly.

## 7. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent build:

**Framework-dependent:**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish/linux-x64
```

Verify the output in the `./publish` directory runs correctly on the target machine.