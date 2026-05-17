# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build context:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types or obsolete APIs, as these may indicate areas where the code relies on legacy behavior.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated to determine whether they indicate a regression introduced by the migration or a pre-existing issue.

## 4. Verify Target Framework

Open each `.csproj` file and confirm that the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure consistency across all projects in the solution, particularly for shared or library projects that are referenced by others.

## 5. Review Removed or Changed APIs

Cross-platform .NET removes or changes certain APIs that were available in .NET Framework. Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any runtime-level compatibility concerns that do not surface as build errors.

Pay particular attention to:
- `System.Configuration` usage
- Windows-specific APIs (registry, WCF, WebForms)
- Reflection-based code that may behave differently across runtimes

## 6. Test on Target Platform

Run the application on the intended target operating system (Linux, macOS, or Windows) to surface any platform-specific runtime issues that would not appear during compilation.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier for your environment (`win-x64`, `osx-x64`, etc.). Use `--self-contained true` if you require the .NET runtime to be bundled with the output.

## 8. Review Output Artifacts

Inspect the contents of the `publish` output directory to confirm all expected assemblies, configuration files, and static assets are present before deploying to the target environment.