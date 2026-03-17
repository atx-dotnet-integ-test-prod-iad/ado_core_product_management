# Next Steps

The transformation appears to have completed successfully. There are no build errors reported across any of the projects in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net48`, `netcoreapp`, or other legacy monikers unless intentionally targeting multiple frameworks.

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts and update them as needed using:

```bash
dotnet list package --outdated
```

## 3. Build the Solution

Perform a full build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types, obsolete APIs, or platform compatibility.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer or the following command to identify any APIs that may not be supported on all target platforms:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to APIs in the following categories, which commonly have cross-platform issues:

- `System.Windows.Forms` or `System.Web` (Windows-only)
- Registry access (`Microsoft.Win32.Registry`)
- File path assumptions (backslash vs. forward slash)
- `System.Drawing` (requires additional native dependencies on Linux/macOS)

## 6. Test on All Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time.

```bash
dotnet run --configuration Release
```

## 7. Validate Configuration Files

Check that any configuration files (`appsettings.json`, `app.config`, `web.config`) have been migrated appropriately. Legacy `app.config` and `web.config` files may need to be converted to `appsettings.json` and read via `Microsoft.Extensions.Configuration`.

## 8. Review Output Artifacts

Publish the application and inspect the output to confirm all required assets, dependencies, and runtime files are present:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the contents of the `./publish` directory before proceeding to any deployment activity.