# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
  </PropertyGroup>
</Project>
```

## 2. Restore and Build

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are zero errors and zero warnings that could indicate compatibility issues.

## 3. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` are compatible with your target framework. Run:

```bash
dotnet list package --outdated
```

Update any outdated packages that have stable releases targeting your framework version.

## 4. Run Existing Tests

If a test project exists in the solution, execute the test suite to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any test failures carefully, as they may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Review the code for any APIs that were available in .NET Framework but are absent or behave differently in cross-platform .NET. Common areas to check include:

- `System.Web` references (not available in .NET Core/.NET 5+)
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage
- WCF server-side components
- `BinaryFormatter` (deprecated and disabled by default)

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.ApiCompat` tool to assist:

```bash
dotnet tool install -g dotnet-apicompat
```

## 6. Test on Target Operating Systems

Since the goal is cross-platform support, run and validate the application on each intended operating system (Windows, Linux, macOS) to catch any platform-specific runtime issues:

```bash
dotnet run --configuration Release
```

Pay attention to file path separators, line endings, and OS-specific environment variables.

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime. For a self-contained deployment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true -o ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed. Review the contents of the `./publish` output directory before deploying.

## 8. Verify Configuration Files

Ensure that any `App.config` or `Web.config` files have been migrated to `appsettings.json` or environment-based configuration, as `System.Configuration.ConfigurationManager` has limited support and `Web.config` is not applicable outside of IIS-hosted applications.