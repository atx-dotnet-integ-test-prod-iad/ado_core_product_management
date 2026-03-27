# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests that previously passed should be investigated before proceeding.

## 4. Verify Target Framework

Open each `.csproj` file and confirm that the `<TargetFramework>` element references the intended .NET version (e.g., `net8.0`). Ensure consistency across all projects in the solution.

## 5. Review Removed or Changed APIs

Cross-platform .NET removes or modifies certain APIs that were available in .NET Framework. Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any runtime-level API usage that may not surface as build errors but could fail at runtime.

Pay particular attention to:
- `System.Web` usages (not available in cross-platform .NET)
- Windows-specific APIs (e.g., registry access, Windows Forms, WCF server-side)
- Reflection-based code that may behave differently under newer runtimes

## 6. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (e.g., Windows, Linux, macOS):

```bash
dotnet run --configuration Release
```

Check for any platform-specific runtime exceptions that would not appear during a Windows-only build.

## 7. Review Configuration Files

Ensure that any `app.config` or `web.config` files have been appropriately migrated to `appsettings.json` or the `Microsoft.Extensions.Configuration` model, as the legacy configuration system is not fully supported in cross-platform .NET.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` flag and `--self-contained` option based on your deployment requirements. Review the publish output directory to confirm all expected files are present.