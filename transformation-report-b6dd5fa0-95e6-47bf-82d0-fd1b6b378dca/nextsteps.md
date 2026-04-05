# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility, as these can indicate subtle issues introduced during migration.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests should be investigated to determine whether they indicate a regression introduced by the migration or a pre-existing issue.

## 4. Verify Target Framework

Open each `.csproj` file and confirm that the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure consistency across all projects in the solution to avoid inter-project compatibility issues.

## 5. Check for Platform-Specific API Usage

Review the code for any APIs that were available in .NET Framework but have limited or no support in cross-platform .NET. Common areas to check include:

- `System.Windows.Forms` or `System.Web` namespaces
- Registry access via `Microsoft.Win32`
- COM interop or P/Invoke calls
- `AppDomain` usage

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining platform-specific dependencies.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier for your deployment target. Refer to the [.NET RID catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog) for a full list of supported identifiers.

## 8. Review Output Artifacts

After publishing, inspect the output directory to confirm all expected assemblies, configuration files, and assets are present before deploying to the target environment.