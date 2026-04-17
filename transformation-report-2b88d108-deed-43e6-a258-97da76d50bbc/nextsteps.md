# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine by running:

```bash
dotnet --version
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts. If any packages were previously targeting .NET Framework exclusively, check NuGet for cross-platform compatible versions.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review all warnings in the build output, as some warnings may indicate API usage that is obsolete or behaves differently on non-Windows platforms.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as failures may indicate platform-specific behavior differences between .NET Framework and cross-platform .NET.

## 5. Check for Platform-Specific API Usage

Even with a successful build, certain APIs may compile but behave differently or throw at runtime on non-Windows platforms. Review the code for usage of:

- `System.Windows.Forms` or `System.Web` namespaces
- Windows Registry access (`Microsoft.Win32.Registry`)
- COM interop or P/Invoke calls targeting Windows-only native libraries
- `AppDomain` APIs that are no longer fully supported

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to surface any remaining compatibility concerns.

## 6. Run the Application on Target Platforms

Execute the application on each platform you intend to support (Windows, Linux, macOS) to catch any runtime issues not surfaced at compile time:

```bash
dotnet run --configuration Release
```

If cross-platform execution is a requirement, test on each OS explicitly rather than assuming behavior is identical.

## 7. Publish the Application

Once validation is complete, publish the application for your target runtime. For a self-contained deployment targeting Linux x64 as an example:

```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

For a framework-dependent deployment:

```bash
dotnet publish -c Release -o ./publish
```

Review the contents of the `./publish` directory to confirm all required assets are present before distributing.