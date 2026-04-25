# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build context:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or platform compatibility analyzers, as these can indicate subtle issues introduced during migration.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests should be investigated to determine whether they represent regressions introduced by the migration or pre-existing issues.

## 4. Verify Target Framework

Open each `.csproj` file and confirm that the `<TargetFramework>` element references the intended cross-platform .NET version (e.g., `net8.0`). Ensure no projects are still targeting `.NET Framework` (e.g., `net472`) unless that is intentional.

## 5. Review Removed or Replaced APIs

Check the codebase for any APIs that were available in .NET Framework but have changed behavior or been removed in modern .NET. The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` compatibility shims can assist with this.

Pay particular attention to:
- `System.Web` usages (not available in cross-platform .NET)
- `AppDomain` APIs with limited support
- Windows-specific registry or COM interop calls
- `BinaryFormatter` (deprecated and disabled by default)

## 6. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (e.g., Windows, Linux, macOS):

```bash
dotnet run --configuration Release
```

Use runtime identifier-specific publishing if needed:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

## 7. Publish the Application

Once validation is complete, publish the application for deployment:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files and dependencies are present before deploying to the target environment.