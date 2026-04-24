# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element targets the intended cross-platform .NET version, for example:

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
Perform a full build to confirm the absence of errors is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that may indicate compatibility issues even if the build succeeds.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review test results carefully. A successful build does not guarantee correct runtime behavior.

### 5. Check for Platform-Specific APIs
Search the codebase for any APIs that are Windows-specific and may compile successfully but fail at runtime on other platforms. Common examples include:

- `Microsoft.Win32` registry access
- `System.Windows.Forms` or `System.Drawing` (without the `EnableWindowsTargeting` workaround)
- P/Invoke calls into Windows-only native libraries

Use the .NET Compatibility Analyzer or run the application on a non-Windows OS to surface these issues.

### 6. Run the Application
Execute the application directly to validate end-to-end behavior:

```bash
dotnet run --project <YourStartupProject>.csproj --configuration Release
```

Walk through the primary use cases to confirm functional correctness.

### 7. Publish a Self-Contained Output
Produce a publish output to verify the application packages correctly for the target runtime:

```bash
dotnet publish --configuration Release --runtime <target-rid> --self-contained true
```

Replace `<target-rid>` with the appropriate Runtime Identifier, for example `win-x64`, `linux-x64`, or `osx-x64`.

Review the publish output folder to confirm all required assets are present.