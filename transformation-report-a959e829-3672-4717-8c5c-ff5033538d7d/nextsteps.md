# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-only TFM such as `net472` or `net48`, update it accordingly.

---

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate runtime issues, such as platform compatibility warnings (`CA1416`).

---

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

---

## 4. Check for Windows-Specific API Usage

Even without build errors, certain APIs may have been replaced with stubs or may throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Pay particular attention to:
- `System.Data` and ADO.NET provider usage (relevant given the `AdoCore` project name)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific threading or interop calls

---

## 5. Validate ADO.NET / Database Connectivity

Given the project name `AdoCore`, verify that any database drivers or providers in use have been updated to their cross-platform compatible NuGet packages. For example:

| Legacy Package | Cross-Platform Replacement |
|---|---|
| `System.Data.SqlClient` | `Microsoft.Data.SqlClient` |
| Oracle ODP.NET (legacy) | `Oracle.ManagedDataAccess.Core` |
| MySql Connector (legacy) | `MySql.Data` or `MySqlConnector` |

Update the relevant `<PackageReference>` entries in `AdoCore.csproj` if needed.

---

## 6. Review NuGet Package Versions

Confirm all NuGet dependencies are targeting .NET-compatible versions:

```bash
dotnet list package --outdated
```

Update any outdated packages that have newer versions with cross-platform support.

---

## 7. Perform Runtime Testing on Target Platform

If the intended deployment platform is Linux or macOS, run the application directly on that platform (or a representative environment) to catch any runtime-only platform issues that static analysis may not surface:

```bash
dotnet run --configuration Release
```

---

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
# Framework-dependent (requires .NET runtime installed on target machine)
dotnet publish --configuration Release --output ./publish

# Self-contained (bundles the runtime)
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate Runtime Identifier (RID) for your target platform (e.g., `win-x64`, `osx-x64`, `linux-arm64`).