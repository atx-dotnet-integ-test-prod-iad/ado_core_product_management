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

Review the output for any warnings about packages that do not fully support the target framework. Consider updating or replacing packages flagged with `NU1701` (package targeting warnings).

## 3. Build the Solution

Perform a clean build to confirm no errors surface outside of the IDE:

```bash
dotnet build --configuration Release
```

Address any warnings that may indicate runtime issues, such as nullable reference warnings or platform compatibility warnings (`CA1416`).

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify functional correctness after migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Failures that did not exist before migration may indicate behavioral differences between .NET Framework and modern .NET, particularly around:

- `System.Configuration` usage
- `AppDomain` behavior
- Reflection differences
- Threading and synchronization primitives

## 5. Validate Platform-Specific Code

Since this is a cross-platform migration, audit the codebase for any APIs that are Windows-specific. You can use the .NET Compatibility Analyzer to assist:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Pay particular attention to:

- Registry access (`Microsoft.Win32.Registry`)
- Windows file path assumptions (backslashes, drive letters)
- `System.Drawing` (requires `libgdiplus` on Linux/macOS or replacement with `System.Drawing.Common`)
- COM interop or P/Invoke calls targeting Windows-only native libraries

## 6. Test on Target Platforms

If cross-platform support is a goal, build and run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues not caught at compile time:

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent deployment as appropriate:

**Framework-dependent:**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Review the contents of the `./publish` directory and confirm all required assets are present before deploying to the target environment.