# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. You can check your installed SDKs by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that may have been replaced during the migration. If any packages targeting the old .NET Framework are still present, locate their cross-platform equivalents on [NuGet.org](https://www.nuget.org).

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Review any warnings in the output, as some warnings may indicate API usage that is obsolete or behaves differently on cross-platform .NET compared to .NET Framework.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Pay close attention to any tests that interact with:
- File system paths (directory separators differ between Windows and Linux/macOS)
- Windows-specific APIs or registry access
- Culture and encoding-sensitive operations

## 5. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any remaining Windows-only API calls. You can add the analyzer via:

```bash
dotnet add package Microsoft.Windows.Compatibility --version <latest>
```

This package provides access to Windows-specific APIs when needed, but also surfaces warnings when such APIs are used, helping you decide whether to replace or conditionally compile them.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during compilation.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime. For a self-contained deployment targeting Linux x64 as an example:

```bash
dotnet publish -c Release -r linux-x64 --self-contained true
```

For a framework-dependent deployment:

```bash
dotnet publish -c Release
```

The output will be placed in the `bin/Release/<tfm>/publish/` directory. Verify the published output runs correctly in the target environment before distributing it.