# Next Steps

The solution has no build errors following the transformation. The steps below cover validation and deployment of the migrated project.

## 1. Review the Migrated Project File

Open `AdoCore.csproj` and confirm the following:

- The `<TargetFramework>` element targets a supported cross-platform .NET version, for example `net8.0`.
- Any remaining `<Reference>` elements that previously pointed to Windows-only assemblies (e.g., `System.Web`, `System.Windows.Forms`) have been replaced with appropriate NuGet packages or removed if no longer needed.
- `<PackageReference>` entries are present for all dependencies that were previously managed via `packages.config`.

## 2. Restore Dependencies

Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Resolve any warnings about deprecated or unlisted packages by updating to current stable versions.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings introduced by the restore step:

```bash
dotnet build --configuration Release
```

Review any warnings, particularly those related to nullable reference types or obsolete APIs, as these may indicate areas that require attention before deployment.

## 4. Run Existing Tests

If the solution contains test projects, execute them to confirm existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully. Failures after migration often indicate platform-specific code paths that were not accounted for during transformation.

## 5. Perform Runtime Validation

Run the application on each target platform (Windows, Linux, macOS as applicable) and verify:

- Application starts without exceptions.
- Core functionality behaves as expected compared to the legacy version.
- Any file paths, configuration files, or environment variables used by the application are handled in a platform-agnostic way (e.g., using `Path.Combine` rather than hardcoded backslashes).

## 6. Check Configuration Files

- If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or equivalent and are being read correctly at runtime.
- Verify that connection strings and other environment-specific values are not hardcoded.

## 7. Validate Target Framework Compatibility

Use the .NET Upgrade Assistant or the compatibility analyzer to check for any remaining API usage that is not supported on the target framework:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <path-to-solution>
```

Address any reported compatibility issues before proceeding to deployment.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed. Review the output directory to confirm all required files are present.