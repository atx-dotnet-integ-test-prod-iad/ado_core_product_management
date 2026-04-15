# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net48`, `netcoreapp`, or other legacy monikers unless intentionally targeting multiple frameworks.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Resolve any warnings about deprecated or unlisted packages by updating to current stable versions in the relevant `.csproj` files.

### 3. Build the Solution
Perform a clean build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet clean
dotnet build --configuration Release
```

Review any warnings in the output, particularly those related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify that behavior has not changed during transformation:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Investigate any failing tests to determine whether they indicate a regression introduced by the migration or a pre-existing issue.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer or the following CLI tool to scan for APIs that are not supported on all platforms:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the build output for `CA1416` platform compatibility warnings, which indicate calls to Windows-only APIs such as those in `Microsoft.Win32` or `System.Windows.Forms`.

### 6. Verify Runtime Behavior
Run the application on each target platform (Windows, Linux, macOS as applicable) to confirm that runtime behavior is consistent. Pay particular attention to:

- File path separators (`/` vs `\`)
- Environment variable access
- Registry access (Windows-only)
- Any use of `AppDomain` or reflection that may behave differently across platforms

### 7. Review Configuration Files
Confirm that any `app.config` or `web.config` files have been replaced or supplemented with `appsettings.json` and the `Microsoft.Extensions.Configuration` stack, as the legacy XML configuration system has limited support in cross-platform .NET.

### 8. Publish a Release Build
Once validation is complete, produce a self-contained or framework-dependent publish artifact to confirm the output is as expected:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Adjust the `--runtime` identifier to match your deployment target (e.g., `win-x64`, `osx-x64`, `linux-arm64`).