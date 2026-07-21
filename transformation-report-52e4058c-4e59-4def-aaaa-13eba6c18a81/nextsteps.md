# Next Steps

## Summary

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution, including `AdoCore.csproj`.

## Validation Steps

### 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

### 2. Build the Solution

Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that, while non-blocking, may indicate compatibility concerns worth addressing (e.g., nullable reference warnings, obsolete API usage).

### 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime, even when the build succeeds.

### 4. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the runtime version available in your target environment.

### 5. Check for Runtime-Only Issues

Some issues do not surface at build time. Manually exercise the core functionality of `AdoCore` to check for:

- Reflection-based code that may behave differently under the new runtime
- Platform-specific APIs (e.g., Windows registry access, COM interop) that may not be available cross-platform
- Configuration file handling differences (e.g., `app.config` vs `appsettings.json`)

### 6. Review Removed or Changed APIs

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any APIs that were available in .NET Framework but are absent or changed in the target .NET version:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <solution-file>.sln
```

### 7. Validate NuGet Package Compatibility

Review all referenced NuGet packages and confirm they support the target framework. Packages that only target `net45`, `net472`, or similar legacy monikers may function via compatibility shims but should be updated to versions with native `netstandard2.0` or `net6.0+` support where available.

### 8. Deploy to Target Environment

Once validation is complete:

1. Publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

2. Verify the contents of the `./publish` directory include all expected assemblies and assets.
3. Run the published output on the target operating system to confirm cross-platform compatibility.