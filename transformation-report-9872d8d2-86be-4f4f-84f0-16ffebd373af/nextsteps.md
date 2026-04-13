# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

### 2. Restore NuGet Packages
Run the following command from the solution root to ensure all dependencies are restored cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages and consider updating them.

### 3. Build the Solution
Perform a full build to confirm there are no errors:

```bash
dotnet build --configuration Release
```

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review the test output for any failures or skipped tests that may indicate behavioral differences between the legacy .NET Framework version and the new cross-platform .NET version.

### 5. Review Removed or Replaced APIs
Check the codebase for any APIs that were available in .NET Framework but have changed behavior in cross-platform .NET. Common areas to inspect include:

- `System.Configuration` — replaced by `Microsoft.Extensions.Configuration`
- `System.Web` — not available on cross-platform .NET
- Windows Registry access (`Microsoft.Win32.Registry`) — only functional on Windows
- `AppDomain` usage — some members are no longer supported
- WCF server-side components — not available in cross-platform .NET without third-party libraries

### 6. Run the Application
Execute the application directly to confirm it starts and operates as expected:

```bash
dotnet run --project AdoCore/AdoCore.csproj --configuration Release
```

Observe any runtime exceptions that would not have been caught at compile time.

### 7. Test on Target Operating Systems
If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific issues such as file path separators, case-sensitive file systems, or OS-specific API calls.

### 8. Review Warnings
Even without errors, the build may have produced warnings. Review them with:

```bash
dotnet build --configuration Release 2>&1 | grep -i warning
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility attributes, as these can indicate future breakage.