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

Confirm there are zero errors and zero unexpected warnings in the output.

---

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by API changes between .NET Framework and modern .NET (e.g., removed APIs, behavioral differences in `System.Data`, threading, or globalization).

---

## 4. Check for Platform-Specific Code

Search the codebase for any remaining Windows-specific dependencies that may compile but fail at runtime on non-Windows platforms:

- `Microsoft.Win32` registry access
- `System.Windows.Forms` or `System.Drawing` (GDI+)
- COM interop (`[ComImport]`, `Marshal`)
- P/Invoke calls targeting Windows-only native libraries
- `AppDomain` usage patterns not supported in .NET Core+

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package to identify these at development time.

---

## 5. Validate ADO.NET Behavior

Since the project is named `AdoCore`, it likely contains data access logic. Verify the following:

- Connection strings are correctly configured for the target environment.
- Any `System.Data` APIs used are available in the target TFM. Most core ADO.NET APIs are supported, but some provider-specific behavior may differ.
- Database provider NuGet packages (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) are updated to versions compatible with modern .NET.

```bash
dotnet list package --outdated
```

Update any outdated packages as appropriate.

---

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application or its tests on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time.

```bash
dotnet run --configuration Release
```

---

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime:

**Framework-dependent (requires .NET runtime installed on target machine):**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (bundles the runtime):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed.

---

## 8. Review Removed or Changed APIs

Consult the official .NET breaking changes documentation if runtime issues are encountered after deployment:

- [Breaking changes in .NET](https://learn.microsoft.com/en-us/dotnet/core/compatibility/breaking-changes)
- [.NET Framework to .NET Core migration guide](https://learn.microsoft.com/en-us/dotnet/core/porting/)