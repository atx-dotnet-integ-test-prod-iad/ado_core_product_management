# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or obsolete APIs, as these may indicate areas that need attention.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review the test results carefully. Any failing tests should be investigated to determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Verify Platform-Specific Behavior

Cross-platform .NET has known differences from .NET Framework in the following areas. Manually verify that your application behaves correctly in each relevant area:

- **File system paths**: .NET on Linux and macOS is case-sensitive. Ensure all file path operations use correct casing or use `Path.Combine` consistently.
- **Registry access**: `Microsoft.Win32.Registry` is not available on Linux/macOS. If the project uses the registry, those code paths will fail on non-Windows platforms.
- **WCF**: Only the client-side WCF libraries are available in cross-platform .NET. Full WCF server hosting is not supported.
- **AppDomain**: Some `AppDomain` APIs are not supported and will throw `PlatformNotSupportedException` at runtime.
- **Serialization**: `BinaryFormatter` is disabled by default in .NET 5+. Replace any usage with a supported serializer such as `System.Text.Json` or `System.Xml.Serialization`.

## 5. Review Target Framework

Open the `.csproj` file for each project and confirm the target framework is set to the intended version:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If any projects still reference `net472` or similar legacy monikers, update them accordingly.

## 6. Check for Removed or Changed APIs

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any API usage that may not be available at runtime despite the project compiling successfully:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Review any diagnostics produced by this analyzer.

## 7. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) and verify that all features function as expected. Pay particular attention to I/O, networking, and any interop code.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) as needed. Review the publish output directory to confirm all required files are present before deploying.