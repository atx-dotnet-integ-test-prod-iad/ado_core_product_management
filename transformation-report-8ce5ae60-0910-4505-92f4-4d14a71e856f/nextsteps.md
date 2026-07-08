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
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and trace them back to API or behavioral differences between .NET Framework and modern .NET.

### 4. Audit NuGet Package Compatibility
Check that all NuGet packages referenced in the project files are compatible with the target framework. Use the following command to inspect outdated or potentially incompatible packages:

```bash
dotnet list package --outdated
```

Replace any packages that have known .NET Framework-only dependencies with their cross-platform equivalents.

### 5. Check for Removed or Changed APIs
Use the [.NET Upgrade Assistant](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the [Microsoft.DotNet.ApiCompat tool](https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-api-compat) to identify any usage of APIs that were removed or changed in modern .NET. Pay particular attention to:

- `System.Web` usages (not available in .NET Core/.NET 5+)
- `AppDomain` APIs with limited support
- Windows-specific APIs if cross-platform execution is required
- Reflection APIs that have behavioral differences

### 6. Validate Runtime Behavior
Run the application and exercise its primary workflows manually or through integration tests. Compare the output and behavior against the legacy .NET Framework version to identify any subtle runtime differences.

### 7. Review Platform-Specific Code
Search the codebase for any platform-specific assumptions such as Windows registry access, Windows file path separators, or COM interop calls. These will compile successfully but will fail at runtime on non-Windows platforms:

```bash
grep -rn "Registry\|Environment.GetFolderPath\|Path.DirectorySeparatorChar\|[Cc]om[Ii]nterop" ./src
```

Address any findings that conflict with your cross-platform goals.

### 8. Deployment
Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the contents of the `./publish` directory and confirm the application runs correctly from that output on the target operating system(s).