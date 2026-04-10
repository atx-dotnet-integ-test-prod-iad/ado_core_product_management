# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate and test the migrated project before deploying it.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element targets the intended cross-platform .NET version (e.g., `net8.0`). Example:

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

Verify there are no warnings that could indicate compatibility issues, such as deprecated APIs or platform-specific code paths.

## 3. Run Existing Tests

If a test project exists in the solution, execute the test suite to confirm existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Review the codebase for any APIs that were available in .NET Framework but are absent or behave differently in cross-platform .NET. Common areas to check include:

- `System.Web` references (not available in .NET Core/.NET 5+)
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage
- `BinaryFormatter` (deprecated and disabled by default)
- `System.Drawing` (requires additional packages on non-Windows platforms)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package to surface any remaining compatibility issues.

## 5. Validate NuGet Package Compatibility

Open the `.csproj` file and review all `<PackageReference>` entries. Confirm each package supports the target framework. You can verify this on [nuget.org](https://www.nuget.org) by checking the package's supported frameworks tab.

## 6. Test on Target Platforms

Since the goal is cross-platform support, run the application on each intended platform (Windows, Linux, macOS) to identify any runtime issues that do not surface during compilation:

```bash
dotnet run --configuration Release
```

Pay particular attention to file path separators, line endings, and any OS-specific behavior.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment. For a self-contained deployment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

For a framework-dependent deployment:

```bash
dotnet publish --configuration Release
```

Review the output in the `publish` folder to confirm all required files are present before deploying to the target environment.