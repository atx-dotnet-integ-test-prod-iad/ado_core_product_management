# Next Steps

The solution has no build errors following the transformation. The migration to cross-platform .NET appears to have completed successfully. The following steps outline how to validate, test, and deploy the project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during the build, particularly those related to nullable reference types or platform compatibility annotations.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully. Failures may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime, such as differences in globalization, string handling, or reflection behavior.

## 4. Verify Platform-Specific Behavior

Cross-platform .NET has known behavioral differences from .NET Framework in the following areas. Manually verify that your application behaves correctly in each relevant area:

- **Globalization and encoding**: .NET on Linux/macOS uses ICU libraries by default rather than Windows NLS. If the application relies on specific culture or encoding behavior, test explicitly on each target platform.
- **Registry access**: `Microsoft.Win32.Registry` APIs are Windows-only. If any code paths use the registry, confirm they are either guarded with runtime OS checks (`OperatingSystem.IsWindows()`) or replaced with cross-platform alternatives.
- **File system case sensitivity**: Linux file systems are case-sensitive. Verify that all file path handling uses consistent casing.
- **Windows Communication Foundation (WCF)**: WCF server-side is not supported on cross-platform .NET. If `AdoCore` or any dependent project uses WCF services, those components will require replacement with alternatives such as gRPC or ASP.NET Core.

## 5. Validate the `AdoCore` Project Specifically

Since `AdoCore` is the project identified in the transformation, confirm the following:

- Any ADO.NET data providers previously referenced (e.g., `System.Data.OleDb`, `System.Data.Odbc`) are available as separate NuGet packages on cross-platform .NET and have been added to the project file if needed.
- Connection strings and database driver dependencies function correctly on the target platform.
- Any use of `System.Data.OracleClient` should be replaced, as it is not available in cross-platform .NET.

## 6. Review the Project File

Open `AdoCore.csproj` and confirm the following:

- The `<TargetFramework>` element targets the intended version, for example `net8.0`.
- No legacy `<PackageReference>` entries point to .NET Framework-only packages.
- The `<Nullable>` and `<ImplicitUsings>` settings are configured according to your project standards.

## 7. Run the Application

Execute the application directly to perform a smoke test:

```bash
dotnet run --project AdoCore --configuration Release
```

If `AdoCore` is a library rather than an executable, write or run a small integration test or console harness that exercises its primary public API.

## 8. Test on All Target Platforms

If cross-platform support is a goal, run the build and tests on each intended operating system (Windows, Linux, macOS) before considering the migration complete.