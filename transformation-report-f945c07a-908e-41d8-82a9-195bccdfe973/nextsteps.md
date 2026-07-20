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

Perform a full solution build to confirm the error-free state holds under a clean build:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that, while not blocking, may indicate compatibility concerns with the new target framework.

### 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as failures may point to behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 4. Review Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with your organization's supported .NET version.

### 5. Check for Runtime-Specific API Usage

Even with a clean build, some APIs that compiled successfully may behave differently or throw at runtime on cross-platform .NET. Pay particular attention to:

- Any usage of `System.Configuration.ConfigurationManager` (requires the `System.Configuration.ConfigurationManager` NuGet package)
- Windows-specific APIs such as the registry, WMI, or COM interop
- `System.Drawing` usage (requires the `System.Drawing.Common` package and may have platform restrictions)
- File path assumptions using backslashes

Run the application on the target platform (Linux/macOS if applicable) and observe runtime exceptions.

### 6. Review Suppressed Warnings

Check the `.csproj` file and any `Directory.Build.props` files for `<NoWarn>` or `<Nullable>` settings that may have been added during transformation. Address any suppressed warnings where practical.

### 7. Smoke Test Core Functionality

Manually exercise the primary entry points of `AdoCore` to confirm that the core functionality works as expected in the new runtime environment. This is particularly important for any networking, serialization, or I/O-heavy code paths that may behave differently across platforms.

### 8. Deployment

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the contents of the `./publish` directory and confirm the output runs correctly on the target machine or operating system.