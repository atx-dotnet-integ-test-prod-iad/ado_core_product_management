# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on all machines that will run or build this project.

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any dependency conflicts or packages that were downgraded. Pay particular attention to any packages that previously targeted `net4x` or `netstandard` and verify their cross-platform compatibility.

## 3. Build the Solution

Perform a clean build to confirm there are no warnings that could indicate runtime issues:

```bash
dotnet build --configuration Release
```

Review any warnings, particularly those related to platform compatibility (e.g., CA1416 platform compatibility warnings), obsolete APIs, or nullable reference types.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify functional correctness after migration:

```bash
dotnet test --configuration Release
```

Review test results carefully. Failures that did not exist before migration may indicate behavioral differences between .NET Framework and modern .NET.

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer or review the code manually for any APIs that are Windows-specific. If the project is intended to run on Linux or macOS, ensure no calls are made to APIs such as:

- `System.Windows.Forms`
- `Microsoft.Win32.Registry`
- `System.Drawing` (without the `System.Drawing.Common` NuGet package and its platform caveats)

If platform-specific code is required, guard it with runtime checks:

```csharp
if (OperatingSystem.IsWindows())
{
    // Windows-specific logic
}
```

## 6. Validate Configuration and App Settings

If the project previously used `App.config` or `Web.config`, verify that configuration has been migrated to `appsettings.json` or environment variables where appropriate, and that `ConfigurationManager` usage has been updated or replaced with `Microsoft.Extensions.Configuration`.

## 7. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time.

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application for your target environment:

**Framework-dependent publish:**
```bash
dotnet publish -c Release -f net8.0
```

**Self-contained publish (example for Linux x64):**
```bash
dotnet publish -c Release -f net8.0 -r linux-x64 --self-contained true
```

Review the contents of the `publish` output folder to confirm all required assets and dependencies are present before deploying to the target environment.