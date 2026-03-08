# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework is set to the intended cross-platform .NET version (e.g., `net6.0`, `net7.0`, or `net8.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts.

## 3. Build the Solution

Perform a full build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Review the codebase for any APIs that were available in .NET Framework but are not fully supported or behave differently in cross-platform .NET. Common areas to check include:

- `System.Drawing` (requires additional packages on non-Windows platforms)
- `Microsoft.Win32` registry access
- Windows Communication Foundation (WCF) client/server usage
- `AppDomain` usage
- `BinaryFormatter` (deprecated and disabled by default)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining compatibility concerns.

## 6. Run the Application

Execute the application directly to perform a basic smoke test:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Verify that the application starts and behaves as expected compared to the legacy version.

## 7. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that do not appear at compile time.

## 8. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent build as appropriate for your deployment target:

**Framework-dependent:**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Review the contents of the `./publish` directory and deploy to your target environment.