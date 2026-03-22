# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-specific TFM such as `net472` or `net48`, update it accordingly.

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate compatibility issues, such as platform-specific API usage.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer or the `dotnet-compatibility` tool to identify any APIs that may not be available on non-Windows platforms:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
dotnet build
```

Pay particular attention to any usage of `System.Windows`, `System.Drawing`, `Microsoft.Win32`, or P/Invoke calls that may be Windows-only.

## 5. Validate NuGet Package Compatibility

Review all NuGet dependencies in `AdoCore.csproj` and confirm that each package supports the target framework. You can inspect compatibility on [nuget.org](https://www.nuget.org) or by checking the package's supported frameworks in your local NuGet cache.

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (e.g., Linux, macOS) to catch any runtime issues that do not surface at compile time:

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# Framework-dependent (requires .NET runtime installed on target machine)
dotnet publish --configuration Release --output ./publish

# Self-contained (includes the runtime)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Replace `linux-x64` with the appropriate RID (e.g., `win-x64`, `osx-x64`, `osx-arm64`) for your deployment target.

## 8. Verify Published Output

Navigate to the `./publish` directory and confirm the expected binaries and configuration files are present. Run the published output directly to confirm it functions as expected outside of the development environment.