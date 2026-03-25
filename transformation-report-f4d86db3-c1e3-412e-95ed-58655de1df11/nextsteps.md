# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other Windows-only frameworks unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify existing behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated before proceeding.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any remaining Windows-specific API calls (e.g., registry access, `System.Windows.Forms`, COM interop) that may compile but fail at runtime on non-Windows platforms.

You can add the analyzer package to assist with this:

```bash
dotnet add package Microsoft.DotNet.Compatibility
```

### 6. Run the Application on Target Platforms
Execute the application on each platform you intend to support (Linux, macOS, Windows) and verify runtime behavior:

```bash
dotnet run --configuration Release
```

Pay attention to file path separators, environment variable differences, and any OS-specific behavior in the application logic.

### 7. Publish a Self-Contained Build
Produce a release build targeting each intended runtime to confirm the publish process completes without errors:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
dotnet publish --configuration Release --runtime win-x64 --self-contained true
dotnet publish --configuration Release --runtime osx-x64 --self-contained true
```

Review the output directory to ensure all required assets and dependencies are present.

### 8. Review Removed or Changed APIs
Cross-reference the [.NET API compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) for any APIs that were available in .NET Framework but have been removed or changed in the target .NET version. Address any identified gaps in the code.