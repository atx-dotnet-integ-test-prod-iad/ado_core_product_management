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

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework APIs and their .NET equivalents.

## 4. Check for Runtime-Only Issues

Some issues do not surface at build time but appear at runtime. Pay attention to the following areas:

- **Reflection-based code**: APIs and behaviors around reflection can differ between .NET Framework and modern .NET.
- **Configuration**: `System.Configuration.ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package on modern .NET. Verify that any configuration loading works as expected.
- **Database/ADO.NET**: Since the project is named `AdoCore`, confirm that all ADO.NET providers (e.g., `System.Data.SqlClient` or `Microsoft.Data.SqlClient`) are explicitly referenced and functioning correctly.
- **Platform-specific APIs**: If the original project used any Windows-only APIs, verify they are either replaced or that the target platform is explicitly set to Windows.

## 5. Validate ADO.NET Provider References

Given the project name, confirm the correct data provider package is referenced in `AdoCore.csproj`. For SQL Server, the recommended package is:

```xml
<PackageReference Include="Microsoft.Data.SqlClient" Version="5.x.x" />
```

Avoid relying on `System.Data.SqlClient` for new development, as `Microsoft.Data.SqlClient` is the actively maintained package.

## 6. Review NuGet Package Compatibility

Run the following command to check for any packages that may not be fully compatible with the target framework:

```bash
dotnet list package --outdated
dotnet list package --deprecated
```

Update any outdated or deprecated packages to versions that explicitly support your target framework.

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required assemblies and dependencies are present. If the project is a library, confirm the resulting `.dll` and `.nupkg` (if applicable) are correctly generated.

## 8. Smoke Test in Target Environment

Deploy the published output to the target environment and perform a basic smoke test to confirm the application runs as expected outside of the development machine. Pay particular attention to:

- Connection strings and environment-specific configuration
- File system paths, which may differ across operating systems if deploying cross-platform
- Any OS-specific behavior that may have been implicitly relied upon in the original project