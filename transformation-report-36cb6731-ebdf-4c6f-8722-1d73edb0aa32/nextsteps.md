# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy the migrated project.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other Windows-only framework monikers unless that is intentional.

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

## 3. Build the Solution

Perform a full build to confirm there are no errors or warnings introduced by the restored packages:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types or platform compatibility (`CA1416`).

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between .NET Framework and cross-platform .NET.

## 5. Check for Windows-Specific API Usage

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for APIs that are Windows-only. You can also run:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to warnings prefixed with `CA1416` (platform compatibility), which indicate APIs that may not function on Linux or macOS.

## 6. Test on Target Platforms

If cross-platform support is a requirement, run the application and its tests on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that static analysis may not catch.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed. Review the publish output directory to confirm all required assets are present.

## 8. Review Configuration Files

Confirm that any `app.config` or `web.config` files have been migrated to `appsettings.json` or equivalent .NET configuration providers, and that environment-specific settings are handled correctly.