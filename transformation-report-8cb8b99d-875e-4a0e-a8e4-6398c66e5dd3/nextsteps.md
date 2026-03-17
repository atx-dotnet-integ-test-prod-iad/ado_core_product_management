# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

### 2. Restore Dependencies
Run the following command from the solution root to ensure all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests should be investigated to determine whether the failure is due to the migration or a pre-existing issue.

### 5. Check for Platform-Specific API Usage
Use the .NET Compatibility Analyzer or review the build output for `CA1416` warnings, which indicate calls to APIs that are only supported on specific platforms (e.g., Windows-only APIs). If any are found, you will need to either:

- Guard the calls with a runtime platform check using `OperatingSystem.IsWindows()`, or
- Replace them with cross-platform alternatives.

### 6. Review `App.config` / `Web.config` Usage
If the legacy project relied on `App.config` or `Web.config`, confirm that configuration has been migrated to `appsettings.json` and that `Microsoft.Extensions.Configuration` is being used where appropriate.

### 7. Verify Output Artifacts
After a successful Release build, inspect the output directory (typically `bin/Release/net8.0/`) to confirm that all expected assemblies, dependencies, and assets are present.

## Deployment

### 1. Publish the Application
Use the `dotnet publish` command to produce deployment artifacts:

```bash
dotnet publish --configuration Release --output ./publish
```

### 2. Framework-Dependent vs. Self-Contained
Decide whether the deployment target will have the .NET runtime installed:

- **Framework-dependent** (smaller output, requires runtime on target machine):
  ```bash
  dotnet publish --configuration Release --runtime linux-x64
  ```
- **Self-contained** (larger output, no runtime required on target machine):
  ```bash
  dotnet publish --configuration Release --runtime linux-x64 --self-contained true
  ```

Replace `linux-x64` with the appropriate Runtime Identifier (RID) for your target environment (e.g., `win-x64`, `osx-x64`).

### 3. Verify the Published Output
Run the published application from the output directory to confirm it starts and behaves as expected before deploying to the target environment:

```bash
dotnet ./publish/AdoCore.dll
```