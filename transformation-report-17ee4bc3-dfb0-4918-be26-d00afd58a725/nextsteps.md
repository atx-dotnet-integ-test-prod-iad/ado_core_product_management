# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`).

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

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they are not hard errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding further.

## 4. Verify Platform-Specific Code

Review any code that previously relied on Windows-specific APIs (e.g., the registry, COM interop, `System.Drawing`, or `Microsoft.Win32` namespaces). These may compile successfully but fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer or test on your target platform directly.

## 5. Check NuGet Package Compatibility

Review all NuGet dependencies in `AdoCore.csproj` and confirm each package supports your target framework. You can check compatibility at [nuget.org](https://www.nuget.org) or by inspecting the package's supported frameworks.

```bash
dotnet list package --outdated
```

Update any outdated packages that have newer cross-platform compatible versions available.

## 6. Test on Target Operating Systems

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application for your target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate Runtime Identifier (RID) for your deployment target (e.g., `win-x64`, `osx-x64`). A full list of RIDs is available in the [Microsoft documentation](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).

## 8. Review Output Artifacts

After publishing, inspect the output directory (typically `bin/Release/net8.0/<rid>/publish/`) to confirm all expected files, configuration files, and assets are present.