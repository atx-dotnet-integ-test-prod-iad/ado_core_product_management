# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and test the migrated project before deploying it.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net4x` or `netstandard` targets unless that is intentional.

## 2. Restore Dependencies

Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings that were not surfaced during the initial transformation:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or obsolete API usage.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as failures may indicate behavioral differences between the legacy .NET Framework APIs and their cross-platform .NET equivalents.

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer to identify any remaining platform-specific API calls that may not behave correctly on non-Windows operating systems:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Review any analyzer warnings and replace platform-specific APIs with cross-platform alternatives where applicable.

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement. Pay particular attention to:

- File path separators (`\` vs `/`)
- Environment variable access
- Registry access (Windows-only)
- Windows-specific authentication or security APIs

## 7. Review Configuration Files

Check that any configuration files (e.g., `appsettings.json`, `app.config`) have been correctly migrated. Legacy `app.config` files may need to be converted to `appsettings.json` for compatibility with the .NET configuration system.

## 8. Publish the Application

Once validation is complete, publish the application using the following command, adjusting the runtime identifier (`-r`) as needed:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

For a self-contained deployment that includes the .NET runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Review the output directory to confirm all required files are present before deploying to the target environment.