# Next Steps

The solution has no build errors following the transformation. Below are steps to validate, test, and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If it still references a Windows-only TFM such as `net472` or `net48`, update it accordingly.

## 2. Review NuGet Package Compatibility

Run the following command to check for any packages that may not be compatible with the target framework:

```bash
dotnet list package --outdated
```

Update any outdated or incompatible packages using:

```bash
dotnet add package <PackageName> --version <LatestVersion>
```

## 3. Restore and Build the Solution

Perform a clean restore and build to confirm there are no runtime or compile-time issues:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate compatibility concerns, even if the build succeeds.

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address the underlying logic or dependency issues they expose.

## 5. Check for Platform-Specific API Usage

Search the codebase for APIs that are Windows-specific and may not behave correctly on Linux or macOS. Common areas to check include:

- `System.Windows.Forms` or `System.Drawing` usage
- Registry access via `Microsoft.Win32.Registry`
- Windows-specific file path assumptions (e.g., backslashes, drive letters)
- COM interop or P/Invoke calls targeting Windows libraries

Use the .NET Compatibility Analyzer to assist with this:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

## 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that do not appear at compile time.

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime. For a self-contained deployment targeting Linux x64 as an example:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

For a framework-dependent deployment:

```bash
dotnet publish --configuration Release
```

Review the output in the `publish` folder and verify all required files and dependencies are present before deploying to the target environment.