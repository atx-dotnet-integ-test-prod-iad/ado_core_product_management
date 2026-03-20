# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on all machines that will build or run this project.

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any dependency conflicts or packages that were downgraded. Pay particular attention to any packages that previously targeted `net4x` or `netstandard` and verify their cross-platform compatibility.

## 3. Build the Solution

Perform a clean build to confirm there are no residual or environment-specific issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types, deprecated APIs, or platform compatibility analyzers (CA1416).

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify behavioral correctness after migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee runtime correctness, so test coverage is critical at this stage.

## 5. Check for Windows-Specific API Usage

Use the .NET Compatibility Analyzer or the `dotnet-compatibility` tool to scan for APIs that may only function on Windows:

```bash
dotnet add package Microsoft.DotNet.ApiCompat
```

Alternatively, review any usages of:
- `Microsoft.Win32` namespaces
- `System.Windows.Forms` or `System.Drawing` (GDI+)
- P/Invoke calls targeting Windows-only native libraries
- Registry access via `Microsoft.Win32.Registry`

If any are found, evaluate whether platform guards (`OperatingSystem.IsWindows()`) or cross-platform alternatives are appropriate.

## 6. Validate Runtime Behavior on Target Platforms

Run the application on each platform you intend to support (Linux, macOS, Windows) to catch any platform-specific runtime issues that static analysis may not surface:

```bash
dotnet run --configuration Release
```

## 7. Review Configuration and File Paths

Ensure that any hardcoded file paths use `Path.Combine` or `Path.DirectorySeparatorChar` rather than backslashes, which are not valid path separators on Linux and macOS.

## 8. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent executable for your target platform:

**Framework-dependent:**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Review the contents of the `./publish` directory and verify the output is complete before deploying to your target environment.