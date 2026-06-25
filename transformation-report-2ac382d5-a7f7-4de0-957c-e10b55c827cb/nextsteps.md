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
Run a full solution build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check both `Debug` and `Release` configurations to rule out configuration-specific issues.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any test failures carefully, as they may indicate behavioral differences between .NET Framework and modern .NET that were not caught at compile time.

### 5. Check for Removed or Changed APIs
Even without build errors, some APIs behave differently on cross-platform .NET. Review the code for usage of the following common problem areas:

- `System.Web` — not available on modern .NET; ensure it has been fully replaced.
- `BinaryFormatter` — deprecated and disabled by default; replace with a supported serializer if used.
- `AppDomain` — some members are no longer functional on modern .NET.
- Windows Registry access — will not function on Linux or macOS.
- File path separators — use `Path.Combine` and `Path.DirectorySeparatorChar` rather than hardcoded backslashes.

### 6. Run on Target Platforms
If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a Windows-only build.

```bash
dotnet run --configuration Release
```

### 7. Review Warnings
Build warnings can indicate future breaking changes or deprecated usage. Run the build with a higher warning level to surface these:

```bash
dotnet build --configuration Release /p:TreatWarningsAsErrors=false /p:WarningLevel=5
```

Address any warnings related to nullable reference types, obsolete members, or platform compatibility attributes.

### 8. Publish the Application
Once validation is complete, publish the application for the target runtime. For a self-contained deployment targeting Linux x64 as an example:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

For a framework-dependent deployment:

```bash
dotnet publish --configuration Release
```

Review the contents of the `publish` output folder to confirm all required assets are present before deploying to the target environment.