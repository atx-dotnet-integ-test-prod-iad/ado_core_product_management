# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If the target framework does not match your intended version, update it and rebuild the solution.

## 2. Restore and Build the Solution

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate compatibility issues, such as deprecated APIs or platform-specific calls.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review the output for any failing tests. Failures may indicate behavioral differences introduced by the migration to cross-platform .NET.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs that compiled successfully may throw at runtime on non-Windows platforms. Review the code for usage of:

- `Microsoft.Win32` registry APIs
- Windows-specific file path assumptions (e.g., backslash separators)
- `System.Drawing` (requires additional native dependencies on Linux/macOS)
- COM interop or P/Invoke calls targeting Windows-only libraries

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package to identify remaining platform-specific concerns.

## 5. Run the Application on Target Platforms

Execute the application on each platform you intend to support (Windows, Linux, macOS) and verify runtime behavior:

```bash
dotnet run --configuration Release
```

Pay attention to:
- File I/O operations and path handling
- Database connectivity (if applicable)
- Any configuration files that may reference platform-specific paths

## 6. Review NuGet Package Compatibility

Confirm that all NuGet dependencies support the target framework. Run the following to check for outdated or incompatible packages:

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

Update any packages that do not support the target framework or have known vulnerabilities.

## 7. Publish the Application

Once validation is complete, publish the application for your target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with your intended runtime identifier (e.g., `win-x64`, `osx-x64`). Review the output in the `publish` directory before deploying to your target environment.