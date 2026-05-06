# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:

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
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding further.

### 4. Check NuGet Package Compatibility
Review all NuGet dependencies in each `.csproj` file. Confirm that every package has a version compatible with the target .NET version. You can use the following command to check for outdated packages:

```bash
dotnet list package --outdated
```

Replace any packages that are not compatible with cross-platform .NET with their recommended alternatives. A common example is replacing `System.Web` dependencies with `Microsoft.AspNetCore` equivalents.

### 5. Review Removed or Changed APIs
Use the [.NET Upgrade Assistant](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the [.NET API compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/api-analyzer) to identify any usage of APIs that are not available or have changed behavior in cross-platform .NET. Run the analyzer with:

```bash
dotnet add package Microsoft.DotNet.ApiCompat
```

### 6. Test on Target Platforms
If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues, such as:

- File path separator differences (`\` vs `/`)
- Case-sensitive file systems on Linux
- Platform-specific APIs that are not available outside of Windows

### 7. Publish the Application
Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) for your target environment. A full list of runtime identifiers is available in the [Microsoft RID catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).