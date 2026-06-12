# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version you intend to support.

## 2. Restore Dependencies

Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts.

## 3. Build the Solution

Perform a clean build to confirm no errors surface outside of the IDE:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or obsolete API usage.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failures may indicate behavioral differences between the legacy .NET Framework APIs and their cross-platform equivalents.

## 5. Check for Platform-Specific API Usage

Even without build errors, some APIs may compile but behave differently or throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Use the .NET Upgrade Assistant compatibility analyzer or the following command to check for platform compatibility issues:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to areas such as:
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific cryptography
- `System.Drawing` (GDI+)
- COM interop

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) you intend to support and exercise the core workflows manually or through integration tests to confirm correct behavior end to end.

## 7. Review Removed or Changed APIs

Cross-reference your codebase against the [.NET breaking changes documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/breaking-changes) for the versions spanning your legacy framework and your new target. Focus on namespaces and types that are central to `AdoCore`.

## 8. Update NuGet Packages

Check for outdated packages and update them to versions that natively target .NET:

```bash
dotnet list package --outdated
```

Prefer packages that target `netstandard2.0` or a specific `net6.0`/`net8.0` TFM over those that only target `net4x`.

## 9. Publish a Release Build

Once validation is complete, publish the application:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the contents of the `./publish` directory and confirm the application runs correctly from that output location on the intended target platform.