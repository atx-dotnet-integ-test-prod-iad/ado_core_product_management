# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between .NET Framework and the new .NET runtime.

## 4. Check for Runtime-Only Issues

Some issues do not appear at compile time but surface at runtime. Pay attention to the following areas:

- **Reflection-based code**: Behavior differences may exist between .NET Framework and modern .NET.
- **Configuration**: `System.Configuration.ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package on modern .NET. Verify all configuration access works as expected.
- **Platform-specific APIs**: Any Windows-only APIs (e.g., registry access, WMI, COM interop) will not function on Linux or macOS. Run the application on each target platform to confirm.
- **ADO.NET providers**: Since this project is named `AdoCore`, confirm that the database driver NuGet packages (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) are the correct cross-platform compatible versions.

## 5. Validate NuGet Package Compatibility

Review all NuGet dependencies in `AdoCore.csproj` and confirm each package supports the target framework. You can check compatibility on [nuget.org](https://www.nuget.org). Replace any packages that only support `net4x` with their modern equivalents.

```bash
dotnet list package --outdated
```

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime failures.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier:

```bash
# Framework-dependent (requires .NET runtime installed on target machine)
dotnet publish --configuration Release --output ./publish

# Self-contained for a specific platform (e.g., Linux x64)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files are present before deploying to the target environment.