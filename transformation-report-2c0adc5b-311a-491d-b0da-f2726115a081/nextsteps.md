# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-only TFM such as `net472` or `net48`, update it accordingly.

---

## 2. Restore and Build the Solution

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Verify that no warnings or errors appear in the output. Pay attention to any `NU` prefixed NuGet warnings, as they may indicate package compatibility issues that did not surface as hard errors.

---

## 3. Check for Windows-Specific API Usage

Even without build errors, the code may contain Windows-specific APIs that will fail at runtime on Linux or macOS. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Rebuild and review any new analyzer warnings related to platform-specific calls such as the Windows Registry, `System.Drawing`, COM interop, or WinForms/WPF dependencies.

---

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite to confirm runtime behavior is intact:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully. Failures that did not exist before the migration may indicate behavioral differences between .NET Framework and modern .NET (e.g., changes in `HttpClient`, serialization defaults, or threading behavior).

---

## 5. Validate Database and ADO.NET Connectivity

Given the project name `AdoCore`, it likely involves ADO.NET data access. Confirm the following:

- The database provider NuGet package is the correct cross-platform version (e.g., `Microsoft.Data.SqlClient` instead of `System.Data.SqlClient` for SQL Server).
- Connection strings are still valid and accessible from the new runtime environment.
- Run integration or smoke tests that exercise actual database reads and writes.

```bash
dotnet add package Microsoft.Data.SqlClient
```

Update any `using System.Data.SqlClient;` references to `using Microsoft.Data.SqlClient;` if applicable.

---

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to catch any runtime-only platform issues:

```bash
dotnet run --configuration Release
```

---

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime:

**Framework-dependent (requires .NET runtime installed on target machine):**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (bundles the runtime):**
```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate Runtime Identifier (RID) for your target environment (`win-x64`, `osx-x64`, etc.).

---

## 8. Review Output Artifacts

Inspect the contents of the `./publish` directory to confirm all expected assemblies, configuration files, and dependencies are present before deploying to the target environment.