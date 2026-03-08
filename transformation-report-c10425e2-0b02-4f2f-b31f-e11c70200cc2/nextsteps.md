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
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Run a full solution build to confirm the error-free state holds outside of any cached build context:

```bash
dotnet build --configuration Release
```

Review warnings in the output. Warnings related to nullable reference types, obsolete APIs, or platform compatibility should be addressed even if they do not block the build.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and modern .NET (e.g., changes in globalization, threading, or serialization behavior).

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any APIs that are Windows-only or otherwise platform-restricted. This is particularly relevant for `AdoCore` if it interacts with system-level resources.

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Address any `CA1416` platform compatibility warnings that surface after adding the analyzer.

### 6. Review `app.config` / `web.config` Migrations
If the original project used `app.config` or `web.config`, confirm that configuration has been migrated to `appsettings.json` or another supported configuration provider. Legacy config sections are not supported in modern .NET without additional packages.

### 7. Validate Runtime Behavior
Execute the application manually or through integration tests and verify:
- All external dependencies (databases, file system paths, network resources) are accessible.
- Serialization and deserialization of any persisted data produces correct results.
- Any reflection-based code functions as expected, since .NET has stricter defaults around reflection in newer versions.

### 8. Review Nullable Reference Type Annotations
If the projects were migrated without enabling nullable reference types, consider enabling them incrementally:

```xml
<Nullable>enable</Nullable>
```

This will surface potential null-dereference issues that were previously undetected.

### 9. Publish a Test Build
Produce a self-contained or framework-dependent publish output and verify it runs on the target platform:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Adjust the `--runtime` flag to match your deployment target (e.g., `linux-x64`, `osx-x64`).