# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this matches the version of the .NET SDK you have installed. You can verify your installed SDKs by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types, obsolete APIs, or platform compatibility.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release
```

Review the test results and investigate any failures, as they may indicate behavioral differences introduced by the migration to cross-platform .NET.

## 5. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant compatibility analyzer or the built-in Roslyn analyzers to identify any remaining Windows-specific API calls that may not behave correctly on Linux or macOS. You can add the compatibility analyzer package to the project:

```xml
<PackageReference Include="Microsoft.DotNet.PlatformAbstractions" Version="*" />
```

Pay particular attention to:
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions (backslashes, drive letters)
- `System.Drawing` usage (requires `libgdiplus` on Linux or replacement with a cross-platform library)
- COM interop or P/Invoke calls targeting Windows-only native libraries

## 6. Test on Target Platforms

Run and test the application on each platform you intend to support (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time:

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application for the desired target platform. For a self-contained deployment targeting Linux x64, for example:

```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

For a framework-dependent deployment:

```bash
dotnet publish -c Release -o ./publish
```

Review the contents of the `./publish` directory and verify that all required assets and configuration files are present before deploying.