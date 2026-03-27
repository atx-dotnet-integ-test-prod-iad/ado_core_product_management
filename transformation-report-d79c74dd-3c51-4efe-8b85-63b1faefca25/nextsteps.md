# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework is set to the intended cross-platform .NET version (e.g., `net6.0`, `net7.0`, or `net8.0`):

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this matches the version of the .NET SDK you have installed. You can check your installed SDKs by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet package restore to confirm all dependencies resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts and update them as needed using:

```bash
dotnet add package <PackageName> --version <Version>
```

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review the build output for any warnings that may indicate compatibility issues, even if they do not prevent compilation.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Even without build errors, some APIs may behave differently or throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Review the code for usage of the following and test on your target platform(s):

- `System.Windows.Forms` or `System.Web` references
- Windows Registry access (`Microsoft.Win32.Registry`)
- COM interop or P/Invoke calls
- `AppDomain` usage beyond what is supported in .NET Core and later

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package to surface these issues statically.

## 6. Run the Application and Perform Smoke Testing

Execute the application directly and verify core functionality:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Test all major code paths, particularly any database access, file I/O, or network communication, as these areas are most likely to surface runtime differences.

## 7. Publish the Application

Once validation is complete, publish the application for your target environment.

For a framework-dependent deployment:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment target.

## 8. Review Output Artifacts

Inspect the contents of the `./publish` directory to confirm all expected assemblies, configuration files, and static assets are present before deploying to your target environment.