# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-only TFM such as `net472` or `net48`, update it accordingly.

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or platform-specific calls that could cause runtime issues even if they do not produce build errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate runtime incompatibilities that were not caught at compile time.

## 4. Check for Platform-Specific API Usage

Even with a successful build, some APIs may be present in .NET but restricted to Windows at runtime. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review any usage of APIs under the `System.Windows`, `Microsoft.Win32`, or `System.Drawing` namespaces, as these may require the `windows` TFM suffix (e.g., `net8.0-windows`) or a replacement library.

## 5. Review NuGet Package Compatibility

Confirm that all NuGet dependencies support the target framework. Run:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with cross-platform support. Pay particular attention to packages that previously targeted only .NET Framework.

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to catch any runtime-only platform issues:

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate RID for your deployment target (e.g., `win-x64`, `osx-x64`). Review the contents of the `publish` output folder before deploying to confirm all required assets are present.

## 8. Review Configuration Files

Ensure that any `App.config` or `Web.config` files have been migrated to `appsettings.json` or environment-based configuration where applicable, as the `ConfigurationManager` approach from .NET Framework has limited or different behavior in cross-platform .NET.