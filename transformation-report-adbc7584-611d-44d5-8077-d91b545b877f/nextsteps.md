# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to deprecated packages or version conflicts. If any packages targeting the old .NET Framework are still present, check for their .NET-compatible equivalents on [NuGet.org](https://www.nuget.org).

## 2. Build the Solution

Perform a full build to confirm there are no issues beyond what was reported:

```bash
dotnet build --configuration Release
```

Review any warnings in the build output. While warnings do not prevent compilation, they may indicate areas of the code that use obsolete APIs or patterns that should be addressed.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review the test results carefully. Any failing tests should be investigated to determine whether the failure is due to a behavioral difference in the new runtime or a pre-existing issue.

## 4. Review Target Framework Monikers

Open each `.csproj` file and confirm that the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure consistency across all projects in the solution, particularly for shared libraries.

## 5. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant or the compatibility analyzer to identify any remaining calls to Windows-specific or Framework-only APIs:

```bash
dotnet add package Microsoft.DotNet.PlatformAbstractions
```

Alternatively, enable the platform compatibility analyzer by setting the following in your `.csproj`:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

Rebuild after adding this to surface any platform-specific warnings.

## 6. Validate Runtime Behavior

Run the application manually and exercise the primary workflows to confirm runtime behavior matches expectations from the legacy version. Pay particular attention to:

- File I/O paths, as path separator behavior differs between Windows and Linux/macOS.
- Configuration file loading, particularly if `app.config` or `web.config` files were used previously.
- Reflection-based code, which may behave differently under the new runtime.

## 7. Review Removed or Changed APIs

Consult the official .NET breaking changes documentation for the versions spanned by your migration:

- [Breaking changes in .NET](https://learn.microsoft.com/en-us/dotnet/core/compatibility/breaking-changes)

Focus on the categories most relevant to your project such as serialization, threading, and globalization.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier for your target environment, such as `linux-x64` or `osx-x64`.

## 9. Verify Output Artifacts

Inspect the contents of the publish output directory to confirm all expected assemblies, configuration files, and static assets are present before deploying to the target environment.