# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

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

Review the output for any warnings that could indicate deprecated APIs or compatibility concerns, even if they are not hard errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches the pre-migration baseline:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any test failures by comparing behavior against the original .NET Framework version.

## 4. Check for Runtime-Only Issues

Some APIs behave differently at runtime even when they compile successfully. Pay particular attention to:

- **Database connectivity**: ADO.NET provider packages (e.g., `System.Data.SqlClient` vs `Microsoft.Data.SqlClient`) may require explicit package references in the new project.
- **Configuration**: `System.Configuration.ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package on .NET Core/.NET 5+.
- **Reflection and serialization**: Verify any dynamic type loading or serialization logic works as expected under the new runtime.

## 5. Review NuGet Package Compatibility

Check that all NuGet dependencies are compatible with your target framework:

```bash
dotnet list package --outdated
dotnet list package --deprecated
```

Update any outdated or deprecated packages to their current stable versions.

## 6. Validate Platform-Specific Behavior

Since this was a cross-platform migration, run the application on each target operating system (Windows, Linux, macOS) if applicable. Areas to verify include:

- File path separators (`\` vs `/`)
- Case sensitivity in file system operations
- Registry access (not available on non-Windows platforms)
- Windows-only APIs that may throw `PlatformNotSupportedException` at runtime

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier:

```bash
# Framework-dependent deployment
dotnet publish --configuration Release --output ./publish

# Self-contained deployment (example for Linux x64)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files and dependencies are present before deploying to the target environment.