# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts. If any packages were previously Windows-only (e.g., packages targeting `net4x`), verify that cross-platform equivalents are in use.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review any warnings in the build output, as some warnings may indicate compatibility concerns that do not prevent compilation but could cause runtime issues.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify behavioral correctness after migration:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests should be investigated to determine whether they are caused by behavioral differences between .NET Framework and modern .NET.

## 5. Check for Platform-Specific API Usage

Even without build errors, some APIs that compiled successfully may throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these issues:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the [.NET API compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) for any APIs used in `AdoCore` that are known to have cross-platform limitations.

## 6. Run the Application

Execute the application directly to verify runtime behavior:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Test all major code paths, particularly any that involve:
- File system access (path separators differ between Windows and Linux/macOS)
- Registry access (not available on non-Windows platforms)
- Windows-specific authentication or security APIs
- ADO.NET database connectivity (verify connection strings and drivers are compatible)

## 7. Validate ADO.NET Data Access

Since the project name suggests ADO.NET usage, confirm the following:

- The database driver NuGet package being used supports .NET (e.g., `Microsoft.Data.SqlClient` instead of `System.Data.SqlClient` for SQL Server).
- Connection strings are correct for the target environment.
- Any `DataSet`, `DataTable`, or `DataAdapter` usage functions as expected, as some serialization behaviors changed between .NET Framework and modern .NET.

## 8. Publish the Application

Once validation is complete, publish the application for your target platform:

```bash
dotnet publish --configuration Release --runtime <RID> --self-contained false
```

Replace `<RID>` with the appropriate Runtime Identifier, for example:
- `win-x64` for Windows
- `linux-x64` for Linux
- `osx-x64` for macOS

Review the publish output directory to confirm all required files are present.