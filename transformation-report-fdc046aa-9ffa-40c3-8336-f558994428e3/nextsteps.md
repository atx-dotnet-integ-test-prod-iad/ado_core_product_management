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

Review the output for any warnings that may indicate deprecated APIs or platform-specific calls that could cause runtime issues even if they do not produce build errors.

---

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

---

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may be present that only function correctly on Windows. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code manually for usage of:
- `Microsoft.Win32` registry APIs
- `System.Windows.Forms` or `System.Drawing` (GDI+)
- COM interop or P/Invoke calls targeting Windows-only libraries
- `AppDomain` APIs that are no-ops or throw on modern .NET

---

## 5. Validate Runtime Behavior on Target Platforms

Run the application on each intended target platform (Linux, macOS, Windows) to confirm consistent behavior:

```bash
dotnet run --configuration Release
```

Pay particular attention to:
- File path separator differences (`\` vs `/`)
- Case-sensitive file systems on Linux
- Environment variable handling differences

---

## 6. Review NuGet Package Compatibility

Confirm that all NuGet dependencies support the target framework. Open the `.csproj` and cross-reference each package version against [nuget.org](https://www.nuget.org) to verify TFM compatibility. Replace any packages that only support `net4x` with their modern equivalents where necessary.

---

## 7. Publish the Application

Once validation is complete, publish the application for the desired target runtime:

**Framework-dependent (requires .NET runtime installed on target machine):**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (bundles the runtime):**
```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, `osx-arm64`, etc.) as needed.

---

## 8. Verify Published Output

Navigate to the `./publish` directory and confirm the expected binaries and assets are present. Run the published output directly to perform a final smoke test:

```bash
./publish/AdoCore
```

On Windows:
```powershell
.\publish\AdoCore.exe
```