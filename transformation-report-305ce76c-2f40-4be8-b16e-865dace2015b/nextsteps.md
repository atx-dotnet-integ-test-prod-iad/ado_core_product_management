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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check NuGet Package Compatibility

Review all NuGet package references in `AdoCore.csproj` and any other projects in the solution. Ensure each package has a version that supports your target framework. You can check compatibility on [nuget.org](https://www.nuget.org). Replace any packages that target only `.NET Framework` with their cross-platform equivalents where applicable.

## 5. Review Removed or Changed APIs

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.ApiCompat` tool to identify any APIs that were available in .NET Framework but are absent or behave differently in .NET. Pay particular attention to:

- `System.Data` and ADO.NET-related APIs if `AdoCore` implies database access.
- Any use of `ConfigurationManager` (replaced by `Microsoft.Extensions.Configuration`).
- Any use of `System.Web` (not available in .NET Core/.NET 5+).

## 6. Validate Runtime Behavior

Run the application against a representative set of inputs or scenarios to confirm that runtime behavior matches the original .NET Framework version. Focus on:

- Database connectivity and query results if the project involves ADO.NET.
- Exception handling paths.
- Any platform-specific file path or encoding assumptions.

## 7. Review Output Artifacts

After a successful Release build, inspect the output directory (typically `bin/Release/net8.0/`) to confirm:

- The correct runtime identifier is targeted if self-contained deployment is needed.
- All expected dependency DLLs are present.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific platform, use:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Adjust the `--runtime` value (`linux-x64`, `osx-x64`, etc.) based on your deployment target.

## 9. Verify Published Output

Test the published output on the target machine or environment to confirm the application starts and operates correctly outside of the development environment.