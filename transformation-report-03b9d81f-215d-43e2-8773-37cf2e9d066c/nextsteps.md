# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net6.0`, `net7.0`, or `net8.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or incompatible packages and update them as needed using:

```bash
dotnet list package --outdated
dotnet add package <PackageName>
```

## 3. Build the Solution

Perform a full build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types or obsolete APIs, as these can indicate potential runtime issues.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully. Failures may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Validate Platform-Specific Behavior

Since this is a cross-platform migration, verify that the following areas behave correctly on your target operating system(s):

- **File paths**: Ensure no hardcoded Windows-style paths (e.g., `C:\...` or backslash separators) exist. Use `Path.Combine` or `Path.DirectorySeparatorChar` where applicable.
- **Registry access**: `Microsoft.Win32.Registry` is not available on Linux/macOS. If the code uses the registry, it will need to be replaced with a cross-platform alternative such as configuration files or environment variables.
- **Windows-only APIs**: Check for any use of `System.Drawing`, COM interop, or WCF server-side components, which have limited or no support on non-Windows platforms.

## 6. Check Runtime Behavior with ADO

Since the project is named `AdoCore`, it likely involves ADO.NET data access. Verify the following:

- The database driver/provider package (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) is compatible with the target .NET version.
- Connection strings are correctly configured for the target environment.
- Any `DataSet`, `DataTable`, or `DataAdapter` usage still functions as expected, as some behaviors differ slightly from .NET Framework.

## 7. Smoke Test Core Functionality

Manually or programmatically exercise the primary entry points of the library or application to confirm expected behavior end-to-end, particularly around data access operations.

## 8. Review Removed or Changed APIs

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.UpgradeAssistant` tool to scan for any remaining compatibility concerns:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <solution>.sln
```

## 9. Publish the Application

Once validation is complete, publish the application for your target platform:

```bash
dotnet publish --configuration Release --runtime <RID> --self-contained false
```

Replace `<RID>` with the appropriate Runtime Identifier, for example:
- `win-x64` for Windows
- `linux-x64` for Linux
- `osx-x64` for macOS

Review the output directory to confirm all required files are present before deploying to the target environment.