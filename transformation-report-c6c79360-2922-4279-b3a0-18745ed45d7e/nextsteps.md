# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional for multi-targeting.

### 2. Restore and Build Locally
Run the following commands from the root of the solution to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

### 4. Check for Removed or Changed APIs
Use the [.NET Upgrade Assistant](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any API usage that may compile successfully but behave differently at runtime on cross-platform .NET.

Run the compatibility analyzer:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
dotnet build
```

### 5. Review NuGet Package Versions
Open the solution's `.csproj` files and verify that all NuGet dependencies have versions compatible with the target .NET version. Check for packages that may have been replaced by built-in .NET APIs, such as:

- `System.Data`
- `System.Configuration.ConfigurationManager`
- `Microsoft.Extensions.Configuration`

Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update packages as needed using:

```bash
dotnet add package <PackageName> --version <LatestVersion>
```

### 6. Validate Platform-Specific Code
Search the codebase for any platform-specific assumptions that may not hold on Linux or macOS, including:

- Windows registry access (`Microsoft.Win32.Registry`)
- Windows-only file path separators (use `Path.Combine` and `Path.DirectorySeparatorChar`)
- COM interop or P/Invoke calls targeting Windows-only libraries

### 7. Run the Application
Execute the application directly to confirm it starts and operates as expected:

```bash
dotnet run --project <YourMainProject>.csproj --configuration Release
```

Perform functional testing against the primary workflows of the application to confirm runtime behavior matches the legacy version.

### 8. Publish a Self-Contained Build
Once runtime validation is complete, produce a self-contained publish output to confirm the application can be deployed without requiring a .NET runtime installation on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime <target-rid>
```

Replace `<target-rid>` with the appropriate Runtime Identifier, for example `win-x64`, `linux-x64`, or `osx-x64`.

Review the publish output directory to confirm all required files are present.