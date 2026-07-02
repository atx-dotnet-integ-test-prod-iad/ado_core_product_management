# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this aligns with the runtime version available in your target environment.

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

If the solution contains test projects, execute them to verify that runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Runtime Compatibility Issues

Even with a clean build, certain APIs behave differently or are unavailable at runtime on cross-platform .NET. Pay particular attention to:

- **Windows-specific APIs**: Any usage of `System.Windows.Forms`, `System.Drawing`, `Microsoft.Win32.Registry`, or similar namespaces may require the `windows` target platform suffix (e.g., `net8.0-windows`) or a compatibility NuGet package.
- **AppDomain and Reflection**: Some `AppDomain` members are no longer supported.
- **Configuration**: `System.Configuration.ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package if not already referenced.
- **Database/ADO.NET**: Since the project is named `AdoCore`, verify that all ADO.NET providers (e.g., `System.Data.SqlClient` vs `Microsoft.Data.SqlClient`) are the correct cross-platform versions.

## 5. Validate ADO.NET Provider References

Given the project name `AdoCore`, confirm that the correct data provider packages are referenced. For SQL Server access, `Microsoft.Data.SqlClient` is the recommended cross-platform package:

```xml
<PackageReference Include="Microsoft.Data.SqlClient" Version="5.x.x" />
```

If the code references `System.Data.SqlClient` directly, consider migrating to `Microsoft.Data.SqlClient` as `System.Data.SqlClient` is no longer actively maintained for cross-platform scenarios.

## 6. Test on Target Operating Systems

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime exceptions that would not appear during a build.

```bash
dotnet run --configuration Release
```

## 7. Review NuGet Package Versions

Check that all NuGet packages referenced in `AdoCore.csproj` are up to date and compatible with your target framework. You can use the following command to identify outdated packages:

```bash
dotnet list package --outdated
```

Update packages where appropriate, and review changelogs for any breaking changes.

## 8. Publish the Application

Once validation is complete, publish the application using the desired runtime identifier:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust `--runtime` to match your deployment target (e.g., `win-x64`, `linux-x64`, `osx-x64`). Use `--self-contained true` if the target environment does not have the .NET runtime installed.