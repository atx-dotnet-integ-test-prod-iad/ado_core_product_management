# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. You can check your installed SDKs by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts and update them in the `.csproj` file as needed.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during the build, particularly those related to nullable reference types or obsolete APIs, as these may indicate compatibility concerns.

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully. Failures may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime, particularly around areas such as:

- `System.Data` and ADO.NET provider behavior
- Connection string formats
- Platform-specific APIs that were previously available on Windows only

## 5. Validate ADO.NET Functionality

Since the project is named `AdoCore`, it likely involves database access. Verify the following:

- The database provider package (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) is referenced and up to date in the `.csproj`.
- Connection strings are correct and accessible in the target environment.
- Any use of `System.Data.OleDb` or `System.Data.Odbc` is reviewed, as these have limited or no support on non-Windows platforms.

Run a manual integration test or a simple console runner against a real or test database instance to confirm connectivity and query execution work as expected.

## 6. Check for Platform-Specific Code

Search the codebase for any APIs that may only function on Windows:

- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific security APIs
- COM interop

If any are found and cross-platform support is required, replace them with cross-platform alternatives or guard them with runtime checks:

```csharp
if (OperatingSystem.IsWindows())
{
    // Windows-specific logic
}
```

## 7. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (e.g., Linux, macOS) to surface any remaining platform-specific issues:

```bash
dotnet run --configuration Release
```

## 8. Review Output Artifacts

Confirm the build output is placed in the expected location and that the assembly version, strong naming (if applicable), and any embedded resources are intact:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to ensure all required files are present before proceeding to any deployment steps.