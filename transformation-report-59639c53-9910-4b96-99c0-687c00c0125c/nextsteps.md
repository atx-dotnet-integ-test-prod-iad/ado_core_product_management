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

Ensure there are no warnings that could indicate compatibility issues, such as platform-specific API usage.

---

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences in the new runtime or by platform-specific code that was not fully migrated.

---

## 4. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer or the `dotnet-compatibility` tool to identify any APIs that may only function on Windows:

```bash
dotnet add package Microsoft.DotNet.ApiCompat
```

Alternatively, enable the platform compatibility analyzer in the `.csproj`:

```xml
<PropertyGroup>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <AnalysisMode>All</AnalysisMode>
</PropertyGroup>
```

Rebuild and review any `CA1416` warnings, which flag Windows-only API calls.

---

## 5. Review NuGet Package Compatibility

Check that all NuGet dependencies support the target framework. Run:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with cross-platform support. Pay particular attention to packages that previously relied on `System.Data`, `System.Drawing`, or COM interop, as these may have limited or changed support in cross-platform .NET.

---

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Linux, macOS, Windows) to surface any runtime issues that static analysis may not catch:

```bash
dotnet run --configuration Release
```

---

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate RID (e.g., `win-x64`, `osx-x64`) based on your deployment environment. Use `--self-contained false` if the target machine has the .NET runtime installed.

---

## 8. Review Output Artifacts

After publishing, verify the contents of the `publish` output directory to confirm all required files, configuration files, and assets are present before deploying to the target environment.