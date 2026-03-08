# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy the migrated project.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless that is intentional.

## 2. Restore NuGet Packages

Run the following command from the solution root to ensure all dependencies are restored cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

## 3. Build the Solution

Perform a full build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or platform compatibility.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any remaining calls to Windows-only APIs (e.g., registry access, `System.Drawing`, WCF server-side components). Replace or conditionally compile these as needed.

## 6. Validate Runtime Behavior on Target Platforms

Run the application on each platform you intend to support (Windows, Linux, macOS) and verify that:

- File path handling works correctly (use `Path.Combine` and avoid hardcoded backslashes).
- Configuration files are loaded as expected.
- Any external dependencies (databases, file system paths, environment variables) resolve correctly on each platform.

## 7. Review Removed or Changed APIs

Consult the [.NET breaking changes documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/breaking-changes) for the specific version you are targeting. Pay particular attention to areas such as:

- `System.Security` and cryptography APIs
- Serialization behavior (`BinaryFormatter` is disabled by default)
- Threading and synchronization context differences

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` flag (`win-x64`, `osx-x64`, etc.) and `--self-contained` flag based on your deployment requirements. Review the output directory to confirm all required files are present before deploying.