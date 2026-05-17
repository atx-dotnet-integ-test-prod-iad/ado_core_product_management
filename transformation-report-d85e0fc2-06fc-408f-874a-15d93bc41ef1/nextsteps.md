# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`).

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate deprecated APIs or missing platform-specific dependencies.

## 3. Review NuGet Package Compatibility

Run the following command to check for any packages that may not be fully compatible with the target framework:

```bash
dotnet list package --outdated
dotnet list package --deprecated
```

Update any outdated or deprecated packages to their latest stable, cross-platform compatible versions.

## 4. Check for Platform-Specific Code

Search the codebase for any APIs that were Windows-specific in the original .NET Framework project. Common areas to review include:

- `System.Web` references (should be replaced with `Microsoft.AspNetCore`)
- Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) client or server code
- `System.Drawing` (replace with a cross-platform alternative such as `SkiaSharp` if needed)

## 5. Run Existing Tests

If the solution contains a test project, execute the tests to verify functional correctness after migration:

```bash
dotnet test --configuration Release --logger trx
```

Review the test results output for any failures or skipped tests that may indicate broken functionality.

## 6. Manual Functional Validation

- Run the application locally and exercise the primary workflows that existed in the legacy project.
- Compare the output and behavior against the known behavior of the original .NET Framework version.
- Pay particular attention to data access logic, serialization, and any file I/O operations, as these areas can behave differently across platforms.

## 7. Validate on Target Operating Systems

If cross-platform support is a goal, run the application on each intended operating system (e.g., Windows, Linux, macOS) to identify any runtime issues that do not surface during a Windows-only build.

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# Framework-dependent deployment
dotnet publish --configuration Release --output ./publish

# Self-contained deployment for a specific platform (e.g., Linux x64)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files are present before deploying to the target environment.