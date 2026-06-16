# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-specific TFM such as `net472` or `net48`, update it accordingly.

---

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or platform-specific code paths that could cause runtime issues even if the build succeeds.

---

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify functional correctness after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between .NET Framework and modern .NET (e.g., changes in `System.Data`, threading, or serialization behavior).

---

## 4. Check for Platform-Specific Code

Search the codebase for APIs that are known to behave differently or be unavailable on non-Windows platforms. Common areas to inspect include:

- `System.Data` and ADO.NET provider usage (relevant given the `AdoCore` project name)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific interop (`DllImport` with Windows-only DLLs)
- `System.Drawing` (requires additional packages on Linux/macOS)

Use the .NET Compatibility Analyzer or the following command to surface platform compatibility warnings:

```bash
dotnet build --configuration Release /p:EnableNETAnalyzers=true
```

---

## 5. Validate ADO.NET / Database Connectivity

Since the project is named `AdoCore`, verify that any database drivers or providers used are compatible with the target .NET version. Confirm the following:

- NuGet packages for database providers (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) are updated to versions that support the target framework.
- Connection strings and configuration are being read correctly (e.g., via `Microsoft.Extensions.Configuration` rather than `System.Configuration.ConfigurationManager` if applicable).
- If `System.Configuration.ConfigurationManager` is still required, ensure the NuGet package `System.Configuration.ConfigurationManager` is referenced in the `.csproj`.

---

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime-only platform issues:

```bash
dotnet run --configuration Release
```

Pay attention to file path separators, line endings, and any OS-specific behavior in database or file I/O operations.

---

## 7. Review Output Type and Entry Point

Confirm that the output type (`Exe` or `Library`) is correctly defined in the `.csproj` and that any entry point (`Main` method or top-level statements) is intact and functioning as expected.

---

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` identifier (`win-x64`, `linux-x64`, `osx-x64`, etc.) and `--self-contained` flag based on your deployment requirements. Review the contents of the `publish` output directory before deploying.