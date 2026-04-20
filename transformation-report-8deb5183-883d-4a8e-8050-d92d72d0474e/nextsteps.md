# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. The following steps outline how to validate, test, and deploy the migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that may not be fully compatible with the target framework.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Address any warnings that surface during the build, as some may indicate compatibility concerns that did not produce hard errors.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release --verbosity normal
```

Review the test output carefully. Any failing tests should be investigated to determine whether they indicate a regression introduced during the migration or a pre-existing issue.

## 5. Validate Platform-Specific APIs

Search the codebase for any APIs that were previously Windows-specific, such as those in `System.Windows.Forms`, `Microsoft.Win32`, or the Windows registry. These may compile successfully but throw `PlatformNotSupportedException` at runtime on non-Windows platforms.

Use the .NET Compatibility Analyzer to assist with this:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Run the build again and review any new analyzer warnings.

## 6. Perform Runtime Validation

Run the application on each target platform (Windows, Linux, macOS) to confirm runtime behavior is consistent. Pay particular attention to:

- File path handling (`Path.Combine` vs hardcoded separators)
- Case sensitivity in file system operations
- Environment variable differences across operating systems
- Any use of `AppDomain`, `Thread.CurrentThread.ApartmentState`, or COM interop

## 7. Review Removed or Changed APIs

Consult the official .NET breaking changes documentation for the version you have migrated to:

[https://learn.microsoft.com/en-us/dotnet/core/compatibility/](https://learn.microsoft.com/en-us/dotnet/core/compatibility/)

Cross-reference any APIs used in `AdoCore` against the breaking changes list for the versions between your original .NET Framework version and your current target.

## 8. Publish the Application

Once validation is complete, publish the application using the desired runtime identifier:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier for your target environment, such as `linux-x64` or `osx-x64`. Use `--self-contained true` if you require the .NET runtime to be bundled with the output.