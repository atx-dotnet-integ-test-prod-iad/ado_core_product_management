# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this aligns with the runtime environment you intend to deploy to.

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

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not cause build failures.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate runtime behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Runtime Compatibility Issues

Even with a clean build, certain APIs behave differently or are unavailable at runtime on cross-platform .NET. Pay particular attention to:

- **Windows-only APIs**: Any usage of `System.Windows.Forms`, `System.Drawing`, `Microsoft.Win32`, or P/Invoke calls to Windows DLLs will not function on Linux or macOS without additional packages or guards.
- **Configuration**: `System.Configuration.ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package on .NET Core/.NET 5+.
- **AppDomain**: Some `AppDomain` members are not supported and will throw `PlatformNotSupportedException` at runtime.
- **Reflection and serialization**: Binary serialization (`BinaryFormatter`) is disabled by default and should be replaced with a supported alternative such as `System.Text.Json` or `System.Xml.Serialization`.

## 5. Review NuGet Package Compatibility

Check all NuGet dependencies to confirm they target .NET Standard 2.0+ or the specific .NET version you are using. Packages that only target `net4x` may have been included via compatibility shims and could cause runtime issues.

```bash
dotnet list package --outdated
```

Update any outdated packages where feasible, and verify that no packages are flagged as deprecated.

## 6. Test on Target Platform

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime failures that would not appear during a Windows-only build.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate RID (e.g., `linux-x64`, `osx-x64`) as needed. Use `--self-contained true` if you want to bundle the .NET runtime with the output.

## 8. Review Output Artifacts

Inspect the `publish` output directory to confirm all expected assemblies, configuration files, and static assets are present before deploying to the target environment.