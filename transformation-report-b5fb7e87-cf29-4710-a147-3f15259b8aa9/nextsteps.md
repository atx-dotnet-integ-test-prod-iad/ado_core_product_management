# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

### 2. Restore NuGet Packages
Run the following command from the solution root to ensure all dependencies resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages.

### 3. Build the Solution
Perform a full build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release
```

Review the test results and investigate any failures, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any APIs that may compile successfully but are not supported on non-Windows platforms at runtime. Pay particular attention to:

- Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) server-side APIs
- `System.Drawing` (GDI+) without the `System.Drawing.Common` NuGet package
- Any P/Invoke calls targeting Windows-only native libraries

### 6. Run the Application
Execute the application directly and exercise its primary code paths to observe runtime behavior:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Compare the output and behavior against the legacy version to confirm functional equivalence.

### 7. Review `app.config` / `web.config` Migrations
Configuration files from .NET Framework projects are not automatically used in cross-platform .NET. Confirm that any relevant settings have been migrated to `appsettings.json` or environment variables, and that `Microsoft.Extensions.Configuration` is being used where appropriate.

### 8. Deployment
Once validation is complete, publish the application using the following command, adjusting the runtime identifier (`-r`) as needed for your target platform:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be pre-installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true -r win-x64 --output ./publish
```

Supported runtime identifiers include `win-x64`, `linux-x64`, and `osx-x64`.