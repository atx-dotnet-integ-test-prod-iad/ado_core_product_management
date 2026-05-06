# Next Steps

The solution has no build errors following the transformation. The migration to cross-platform .NET appears to have completed successfully. The following steps outline how to validate, test, and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no legacy `<TargetFrameworkVersion>` or `<TargetFrameworkIdentifier>` elements referencing `.NETFramework` remain in the file.

## 2. Review NuGet Package References

Check that all `<PackageReference>` entries in `AdoCore.csproj` reference packages that support the target framework. Run the following command to restore and check for compatibility warnings:

```bash
dotnet restore
```

Review any `NU1701` or similar warnings that indicate a package was restored for a different framework and may not be fully compatible.

## 3. Build the Solution

Perform a clean build to confirm there are no errors:

```bash
dotnet build --configuration Release
```

Review the build output for any warnings that may indicate runtime issues even if the build succeeds.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests and determine whether they are caused by behavioral differences between .NET Framework and cross-platform .NET, such as changes in globalization, file path handling, or reflection behavior.

## 5. Validate Platform-Specific Code

Search the codebase for any APIs that are not supported on all platforms. Common areas to check include:

- `System.Windows.Forms` or `System.Web` references, which are not cross-platform
- Registry access via `Microsoft.Win32.Registry`
- `System.Drawing` usage, which requires additional native dependencies on Linux and macOS
- P/Invoke calls targeting Windows-only native libraries

Use the .NET Compatibility Analyzer to assist with this:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

## 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that do not appear at compile time.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier such as `linux-x64` or `osx-x64` if targeting other platforms. Review the contents of the publish output directory to confirm all required files are present before deployment.