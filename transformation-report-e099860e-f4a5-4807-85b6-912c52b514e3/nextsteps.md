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

If the solution contains test projects, execute them to verify that runtime behavior has not changed after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Runtime-Only Issues

Some issues do not surface at build time but appear at runtime. Pay particular attention to:

- **Reflection-based code**: Behavior differences may exist between .NET Framework and modern .NET.
- **Configuration**: `System.Configuration.ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package on cross-platform .NET. Verify all configuration access works as expected.
- **Platform-specific APIs**: Any APIs that were Windows-only (e.g., registry access, certain COM interop) will not function on non-Windows platforms. Use the [.NET Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to identify these.

## 5. Review NuGet Package Compatibility

Ensure all NuGet packages referenced in `AdoCore.csproj` are compatible with the target framework. Check for packages that have not been updated in a long time or that still target only `net45`/`net472` etc. Use the following to inspect current package versions:

```bash
dotnet list package --outdated
```

Update packages where appropriate:

```bash
dotnet add package <PackageName>
```

## 6. Validate ADO.NET Data Access

Given the project name (`AdoCore`), it likely contains ADO.NET data access logic. Verify the following:

- Connection strings are correctly sourced from the new configuration system.
- Any `System.Data` usage is functioning correctly at runtime against your target database.
- If `System.Data.SqlClient` was used previously, consider migrating to `Microsoft.Data.SqlClient`, which is the actively maintained package for SQL Server access on modern .NET:

```bash
dotnet add package Microsoft.Data.SqlClient
```

Update any `using` directives accordingly:

```csharp
using Microsoft.Data.SqlClient;
```

## 7. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended platform (Windows, Linux, macOS) to catch any platform-specific runtime issues that would not appear in a Windows-only build and test cycle.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment (no .NET runtime required on the target machine):

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier for your target platform (e.g., `linux-x64`, `osx-x64`).