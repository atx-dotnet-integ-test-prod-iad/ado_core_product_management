# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this is consistent with any dependent or consuming projects in the solution.

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

If the solution contains test projects, execute them to verify that behavior has not changed after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate runtime behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Runtime-Only Issues

Some issues do not surface at build time but appear at runtime. Pay particular attention to the following areas:

- **Reflection-based code**: Behavior differences may exist between .NET Framework and modern .NET.
- **Configuration**: `System.Configuration.ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package on modern .NET. Verify all configuration access works as expected.
- **Platform-specific APIs**: Any Windows-only APIs (e.g., registry access, COM interop, WMI) will not function on Linux or macOS. Use the [Platform Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to identify these.
- **ADO.NET providers**: Since this project appears to be ADO-related (`AdoCore`), confirm that the database driver NuGet packages (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, etc.) are referencing current, cross-platform compatible versions.

## 5. Review NuGet Package Versions

Run the following command to identify outdated packages:

```bash
dotnet list package --outdated
```

Update packages that have newer stable versions available, particularly any that were carried over from the legacy project, as older versions may not fully support modern .NET.

## 6. Validate Cross-Platform Behavior

If cross-platform support is a goal, test the application on at least one non-Windows environment (Linux or macOS) to confirm there are no platform-specific runtime failures. Pay close attention to:

- File path separators (`\` vs `/`)
- Case-sensitive file system differences
- Environment variable access

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier:

```bash
# Framework-dependent (requires .NET runtime installed on target machine)
dotnet publish --configuration Release --output ./publish

# Self-contained (bundles the runtime)
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier for your target environment (e.g., `linux-x64`, `osx-x64`).

## 8. Review Output Artifacts

After publishing, inspect the `./publish` directory to confirm all expected assemblies, configuration files, and dependencies are present before deploying to the target environment.