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

Review the output for any warnings about deprecated packages or version conflicts. If any packages were previously targeting .NET Framework, check their NuGet pages to confirm they support the target cross-platform .NET version.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet clean
dotnet build
```

Address any warnings that appear, particularly those related to nullable reference types or obsolete APIs, as these can become errors in stricter build configurations.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior has not changed:

```bash
dotnet test
```

Review the test results carefully. Any failing tests should be investigated to determine whether they indicate a regression introduced during migration or a test that requires updating due to API changes.

## 5. Check for Platform-Specific Code

Search the codebase for any APIs that were available in .NET Framework but are not available or behave differently in cross-platform .NET. Common areas to review include:

- `System.Web` references (not available in cross-platform .NET)
- Windows Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) client or server code
- `AppDomain` usage beyond what is supported
- `BinaryFormatter` usage, which is disabled by default in modern .NET

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining compatibility concerns.

## 6. Test on Target Platforms

Since the goal is cross-platform compatibility, run and validate the application on each platform you intend to support (Windows, Linux, macOS):

```bash
dotnet run
```

Pay attention to file path separators, line endings, and any OS-specific behavior in the application logic.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment. For a self-contained deployment:

```bash
dotnet publish -c Release -r <runtime-identifier> --self-contained true
```

Replace `<runtime-identifier>` with the appropriate value, such as `win-x64`, `linux-x64`, or `osx-x64`.

For a framework-dependent deployment:

```bash
dotnet publish -c Release
```

Review the contents of the `publish` output directory to confirm all required files are present before deploying to the target environment.