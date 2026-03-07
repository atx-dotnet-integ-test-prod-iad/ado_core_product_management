# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other legacy/end-of-life monikers unless intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved references.

### 3. Build the Solution
Perform a full build to confirm there are no warnings that may indicate compatibility issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility analyzers.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review test output for any failures that may indicate behavioral differences introduced by the migration.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the built-in platform compatibility analyzer to identify any remaining calls to Windows-only or otherwise platform-specific APIs. These will typically surface as analyzer warnings (e.g., `CA1416`).

You can also run:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

### 6. Review `App.config` / `Web.config` Usage
If the original project relied on `App.config` or `Web.config`, confirm that configuration has been migrated to `appsettings.json` and that `Microsoft.Extensions.Configuration` is being used where appropriate.

### 7. Validate Runtime Behavior
Run the application directly and exercise its primary workflows to confirm functional parity with the original legacy version:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

### 8. Publish the Application
Once validation is complete, publish a self-contained or framework-dependent release build:

**Framework-dependent:**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all expected output files are present before deploying to the target environment.