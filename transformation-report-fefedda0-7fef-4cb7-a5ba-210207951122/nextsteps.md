# Next Steps

The solution has no build errors following the transformation. Below are steps to validate, test, and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If it still references a Windows-only TFM such as `net472` or `net48`, update it accordingly.

## 2. Review NuGet Package Compatibility

- Open the NuGet Package Manager or inspect the `.csproj` file directly.
- Ensure all referenced packages have versions that support the target TFM.
- Run the following command to restore and check for any compatibility warnings:

```bash
dotnet restore
```

Address any `NU1701` or similar compatibility warnings that appear in the output.

## 3. Build the Solution

Perform a clean build from the command line to confirm there are no hidden build issues:

```bash
dotnet build --configuration Release
```

Review the output for any warnings that could indicate runtime issues even if the build succeeds.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify functional correctness:

```bash
dotnet test --configuration Release
```

Review test results and investigate any failures before proceeding.

## 5. Check for Platform-Specific API Usage

Even without build errors, the code may reference Windows-specific APIs that will fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these:

- Ensure the `Microsoft.DotNet.Analyzers.Compatibility` or the built-in platform compatibility analyzers are active.
- Look for any `CA1416` warnings indicating platform-specific calls.
- Replace or conditionally guard any Windows-only APIs using `OperatingSystem.IsWindows()` where appropriate.

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS as applicable) to confirm runtime behavior is correct:

```bash
dotnet run --configuration Release
```

Pay particular attention to:
- File path separators (`/` vs `\`)
- Environment variable access
- Registry access (Windows-only)
- Any use of `System.Windows.Forms` or `System.Drawing` which require additional configuration on non-Windows platforms

## 7. Publish the Application

Once validation is complete, publish the application for the desired target:

**Framework-dependent (smaller output, requires .NET runtime installed):**
```bash
dotnet publish -c Release -f net8.0
```

**Self-contained (includes the runtime, no external dependency):**
```bash
dotnet publish -c Release -f net8.0 --self-contained true -r linux-x64
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, `osx-arm64`, etc.) as needed.

## 8. Review Output Artifacts

After publishing, inspect the output directory (typically `bin/Release/net8.0/publish/`) to confirm all expected files, configuration files, and assets are present.