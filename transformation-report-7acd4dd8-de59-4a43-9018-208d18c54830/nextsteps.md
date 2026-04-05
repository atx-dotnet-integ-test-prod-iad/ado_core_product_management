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

Confirm there are no warnings or errors in the output before proceeding.

---

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is intact:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address regressions introduced during the migration.

---

## 4. Check for Windows-Specific API Usage

Even without build errors, the code may contain APIs that only function on Windows. Use the .NET Compatibility Analyzer to surface these at build time by adding the following to `AdoCore.csproj`:

```xml
<PropertyGroup>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <AnalysisMode>All</AnalysisMode>
</PropertyGroup>
```

Rebuild and review any `CA1416` (platform compatibility) warnings that appear.

---

## 5. Validate NuGet Package Compatibility

Confirm that all referenced NuGet packages support the target framework:

```bash
dotnet list package --outdated
dotnet list package --deprecated
```

Update or replace any packages that do not support the cross-platform .NET target.

---

## 6. Test on Target Platforms

Run the application on each platform you intend to support (Linux, macOS, Windows) to catch any runtime behavior differences that static analysis would not detect:

```bash
dotnet run --configuration Release
```

Pay particular attention to:
- File path separators
- Environment variable access
- Registry access (not available on non-Windows platforms)
- `System.Drawing` or other Windows-dependent libraries

---

## 7. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent build as appropriate for your deployment target.

**Framework-dependent:**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Review the contents of the `./publish` directory and deploy to your target environment.