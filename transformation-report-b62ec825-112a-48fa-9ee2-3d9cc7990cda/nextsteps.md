# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Run a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Review any warnings that surface during the build, as some warnings may indicate compatibility concerns that did not produce hard errors.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review test output carefully, particularly for any tests that exercise platform-specific behavior such as file paths, registry access, or Windows-specific APIs.

### 5. Check for Removed or Replaced APIs
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` compatibility tooling to scan for any API usage that may compile successfully but behave differently at runtime on non-Windows platforms:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to:
- `System.Drawing` usage (replaced by cross-platform alternatives such as `SkiaSharp` or `ImageSharp`)
- `Microsoft.Win32` registry access
- `System.Security.Permissions` attributes
- Any P/Invoke calls targeting Windows-specific native libraries

### 6. Run the Application
Execute the application directly to confirm it starts and operates correctly:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

If the project is a library rather than an executable, write a small integration test or console harness to exercise its primary entry points.

### 7. Verify on Target Platforms
If cross-platform support is a goal, run the build and test steps above on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during compilation.

### 8. Publish the Application
Once validation is complete, produce a published output:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assets, configuration files, and dependencies are present before deploying to the target environment.