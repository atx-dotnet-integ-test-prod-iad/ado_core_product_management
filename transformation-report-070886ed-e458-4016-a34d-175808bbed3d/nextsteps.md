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

Review the output for any warnings that may indicate compatibility issues, deprecated APIs, or platform-specific code paths that were silently carried over.

---

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate runtime behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

---

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been carried over that are Windows-specific and will fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to identify these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code for usage of:
- `System.Windows.Forms` or `System.Drawing` (without the `-windows` TFM suffix)
- `Microsoft.Win32` registry APIs
- COM interop or P/Invoke calls targeting Windows-only DLLs

---

## 5. Validate NuGet Package Compatibility

Check that all NuGet dependencies support the target framework. Run:

```bash
dotnet list package --outdated
```

Replace any packages that do not support the new TFM with their modern equivalents. Pay particular attention to packages that previously targeted `net45`, `net472`, or similar legacy monikers.

---

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Linux, macOS, Windows) to surface any runtime-only platform issues:

```bash
dotnet run --configuration Release
```

Test all major code paths, especially those involving file I/O, networking, or database access, as these areas commonly surface platform differences.

---

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
# Framework-dependent (requires .NET runtime on target machine)
dotnet publish --configuration Release --output ./publish

# Self-contained (bundles the runtime)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assets are present before deploying.