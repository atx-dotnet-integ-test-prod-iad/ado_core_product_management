# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to deprecated packages or version conflicts. If any packages targeting the old .NET Framework are still referenced, consider finding their cross-platform equivalents on [NuGet.org](https://www.nuget.org).

## 2. Build the Solution

Perform a full build to confirm there are no issues beyond what was reported:

```bash
dotnet build --configuration Release
```

Review any warnings in the build output. While warnings do not prevent a build from succeeding, they may indicate areas of the code that could cause runtime issues.

## 3. Run Unit Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review the test results carefully. Any failing tests should be investigated before proceeding further.

## 4. Verify Target Framework

Open each `.csproj` file and confirm that the `<TargetFramework>` element is set to the intended cross-platform version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If any project still targets `net472` or another .NET Framework moniker, update it accordingly and re-run the build and tests.

## 5. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been available in .NET Framework but behave differently or are unavailable at runtime on Linux or macOS. Use the .NET Upgrade Assistant or the Platform Compatibility Analyzer to identify any such usages:

```bash
dotnet add package Microsoft.DotNet.PlatformAbstractions
```

Additionally, review any usage of the following areas manually:
- `System.Windows.Forms` or `System.Web` (not supported cross-platform)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions (e.g., backslashes, drive letters)
- COM interop or P/Invoke calls targeting Windows-only native libraries

## 6. Run the Application

Execute the application directly to confirm it runs as expected:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Test the primary workflows and features of the application manually to confirm runtime behavior matches expectations.

## 7. Publish the Application

Once validation is complete, publish the application for your target platform. For a self-contained deployment targeting Linux x64 as an example:

```bash
dotnet publish ./AdoCore/AdoCore.csproj --configuration Release --runtime linux-x64 --self-contained true -o ./publish
```

For a framework-dependent deployment:

```bash
dotnet publish ./AdoCore/AdoCore.csproj --configuration Release -o ./publish
```

Review the contents of the `./publish` directory to confirm all expected files are present before deploying to the target environment.