# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other .NET Framework moniker unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm there are no errors or warnings that were not surfaced during the initial transformation:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

### 4. Run the Test Suite
If the solution contains test projects, execute all tests to verify that behavior has not changed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in globalization, file path handling, or reflection behavior).

### 5. Check for Platform-Specific API Usage
Use the .NET Compatibility Analyzer to identify any APIs that may not be supported on all target platforms. This can be done by reviewing build warnings prefixed with `CA1416`. If any are present, evaluate whether platform guards or alternative APIs are needed.

### 6. Review `App.config` / `Web.config` Usage
Cross-platform .NET does not use `App.config` or `Web.config` in the same way as .NET Framework. Confirm that any configuration previously held in those files has been migrated to `appsettings.json` or another supported configuration provider.

### 7. Validate Runtime Behavior
Run the application manually and exercise the primary workflows to confirm that runtime behavior matches expectations. Pay particular attention to:

- File I/O operations, since path separators differ between Windows and Unix-based systems.
- Registry access, which is Windows-only.
- Any use of `System.Drawing` or WinForms/WPF components, which have platform restrictions.
- COM interop or P/Invoke calls that may not function on non-Windows platforms.

## Deployment

### 1. Publish the Application
Use the `dotnet publish` command to produce deployment artifacts:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier for your target environment (e.g., `linux-x64`, `osx-x64`).

### 2. Verify the Published Output
Navigate to the output directory and confirm all expected files are present, including configuration files and any required static assets.

### 3. Test the Published Artifacts
Run the published application directly from the output directory on the target operating system to confirm it functions correctly outside of the development environment.