# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy the migrated project.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net48`, `netcoreapp`, or other legacy monikers unless there is a specific reason to multi-target.

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings that were not captured previously:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility analyzer warnings.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated to determine whether they indicate a regression introduced during migration or a pre-existing issue.

## 5. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant compatibility analyzer or the built-in platform compatibility analyzer to identify any APIs that may not be available on all target platforms (Linux, macOS, Windows). Look for warnings with codes such as `CA1416`.

```bash
dotnet build /p:EnableNETAnalyzers=true
```

Replace or guard any platform-specific calls with appropriate abstractions or runtime checks using `OperatingSystem.IsWindows()`, etc.

## 6. Validate Runtime Behavior

Run the application locally on each target platform (or at minimum on the primary deployment platform) and exercise the core workflows manually to confirm runtime behavior matches expectations from the legacy version.

## 7. Review Configuration Files

Check that any configuration files (`appsettings.json`, `app.config`, `web.config`) have been correctly migrated. Legacy `app.config` and `web.config` settings may need to be moved to `appsettings.json` and read via `Microsoft.Extensions.Configuration`.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Adjust the `--runtime` flag and `--self-contained` option based on your deployment environment. Review the contents of the publish output directory to confirm all required assets are present before deploying.