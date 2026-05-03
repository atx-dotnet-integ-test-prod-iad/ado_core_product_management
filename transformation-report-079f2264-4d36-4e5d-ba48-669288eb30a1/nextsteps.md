# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy the migrated project.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net48`, `netcoreapp`, or other legacy monikers unless intentionally targeting multiple frameworks.

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that lack cross-platform support.

## 3. Build the Solution

Perform a full build to confirm there are no issues that may not have surfaced during the transformation analysis:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types, platform compatibility (`CA1416`), or obsolete APIs.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failed or skipped tests and investigate the root cause of each failure.

## 5. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any remaining Windows-specific API calls (e.g., registry access, `System.Windows.Forms`, `System.Drawing.Common`) that may compile but fail at runtime on non-Windows platforms.

```bash
dotnet add package Microsoft.Windows.Compatibility
```

Only add this package if Windows-specific APIs are required and the application is intentionally Windows-only. Otherwise, replace those APIs with cross-platform alternatives.

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) to confirm runtime behavior is consistent:

```bash
dotnet run --configuration Release
```

Pay particular attention to:
- File path separators (`/` vs `\`)
- Case sensitivity in file system operations
- Environment variable access
- Culture and encoding differences

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true -o ./publish
```

Replace `linux-x64` with the appropriate RID (`win-x64`, `osx-x64`, `osx-arm64`, etc.) as needed. Review the contents of the `./publish` directory to confirm all required assets are present before deployment.