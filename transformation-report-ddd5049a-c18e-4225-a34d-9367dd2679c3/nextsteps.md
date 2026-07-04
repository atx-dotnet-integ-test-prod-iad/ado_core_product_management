# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless a multi-targeting scenario is intentional.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even though they do not block compilation.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding further.

### 4. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any APIs that are Windows-only or otherwise platform-restricted. You can also run:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay attention to `CA1416` (platform compatibility) warnings in the output.

### 5. Review NuGet Package Versions
Open the `.csproj` files and verify that all NuGet dependencies reference versions that support your target framework. Cross-check on [nuget.org](https://www.nuget.org) if any packages appear outdated or have known compatibility issues with modern .NET.

### 6. Validate Runtime Behavior
Run the application locally and exercise the primary workflows to confirm behavior matches the legacy version. Pay particular attention to:

- File I/O paths (path separators differ between Windows and Linux/macOS)
- Registry access (not available on non-Windows platforms)
- Windows Communication Foundation (WCF) usage, if any
- Any use of `System.Drawing` which has platform restrictions in .NET 6+

### 7. Publish the Application
Once the above checks pass, produce a published output using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all expected assemblies and assets are present.

### 8. Test the Published Output
Run the published output directly rather than through `dotnet run` to simulate the production environment:

```bash
./publish/AdoCore
```

Confirm the application starts and operates correctly from the published artifacts before deploying to the target environment.