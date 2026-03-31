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

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated to determine whether they reflect regressions introduced by the migration or pre-existing issues.

## 4. Verify Target Framework

Open each `.csproj` file and confirm that the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure consistency across all projects in the solution, particularly for shared libraries.

## 5. Review Removed or Changed APIs

Cross-platform .NET removes or modifies certain APIs that were available in .NET Framework. Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any runtime-level API usage that may not surface as build errors but could fail at runtime.

Pay particular attention to:
- `System.Web` dependencies
- Windows-specific registry or COM interop calls
- `AppDomain` usage
- `BinaryFormatter` serialization

## 6. Test on Target Platform

If the intent is cross-platform execution, run the application on each target operating system (Windows, Linux, macOS) to identify any platform-specific runtime failures that would not appear during a Windows-only build.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier for your environment. Use `--self-contained false` if the target machine has the .NET runtime installed.

## 8. Review Output Artifacts

Inspect the `publish` output directory to confirm all expected files, configuration files, and assets are present before deploying to the target environment.