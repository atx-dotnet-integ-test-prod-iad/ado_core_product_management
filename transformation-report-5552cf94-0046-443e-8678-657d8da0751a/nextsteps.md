# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`).

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If the TFM does not match your intended runtime, update it and rebuild the solution.

## 2. Restore and Build the Solution

Run the following commands from the root of your solution to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Review NuGet Package Compatibility

Run the following command to check for any outdated or potentially incompatible packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions compatible with your target framework. Pay particular attention to packages that previously targeted `net4x` or `netstandard1.x`.

## 4. Check for Removed or Changed APIs

Even without build errors, some APIs behave differently or have been removed in modern .NET. Review the [.NET Upgrade Assistant compatibility analyzer output](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or run the compatibility analyzer:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <path-to-solution>
```

Address any reported compatibility warnings.

## 5. Run Existing Tests

If the solution contains test projects, execute them to validate runtime behavior:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework and modern .NET.

## 6. Perform Manual Functional Testing

- Run the application locally and exercise all major code paths.
- Pay attention to areas that commonly differ between .NET Framework and modern .NET, such as:
  - `System.Configuration` usage (replaced by `Microsoft.Extensions.Configuration`)
  - WCF or Remoting (not fully supported on modern .NET)
  - `AppDomain` isolation
  - File path handling on non-Windows platforms
  - Reflection behavior changes

## 7. Validate Cross-Platform Behavior (If Applicable)

If cross-platform support is a goal, test the application on Linux or macOS:

```bash
dotnet run --configuration Release
```

Check for any platform-specific issues such as:
- Case-sensitive file paths
- Windows-only registry access
- Platform-specific P/Invoke calls

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier:

**Framework-dependent (requires .NET runtime on target machine):**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (includes the runtime):**
```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with your target platform (e.g., `win-x64`, `osx-x64`).

## 9. Verify Published Output

Navigate to the `./publish` directory and confirm all expected files are present. Run the published output directly to verify it behaves as expected in a production-like environment.