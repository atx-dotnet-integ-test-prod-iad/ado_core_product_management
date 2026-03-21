# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

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

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework. Replace any packages that only support `.NETFramework` with their cross-platform equivalents if warnings are present.

## 3. Build the Solution

Perform a clean build to confirm no errors or warnings are introduced at compile time:

```bash
dotnet clean
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types, obsolete APIs, or platform compatibility.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between .NET Framework and modern .NET (e.g., changes in `System.Data`, threading, or serialization).

## 5. Validate Platform-Specific Code

Search the codebase for any APIs that may have been available in .NET Framework but behave differently or are unavailable in cross-platform .NET:

- `System.Web` references (not available outside Windows)
- `Registry` access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) server-side components
- `AppDomain.CreateDomain` (not supported)
- `BinaryFormatter` (disabled by default in .NET 5+)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining compatibility concerns.

## 6. Test on Target Platforms

Since the goal is cross-platform support, run and validate the application on each intended operating system:

```bash
# On Linux or macOS
dotnet run --configuration Release
```

Pay attention to:
- File path separators (`\` vs `/`)
- Case-sensitive file systems on Linux
- Environment variable differences across platforms

## 7. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent build as appropriate:

**Framework-dependent:**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish/linux-x64
```

Verify the output in the `./publish` directory runs correctly on the target machine.

## 8. Review Configuration Files

Ensure any `App.config` or `Web.config` files have been migrated to `appsettings.json` or environment-based configuration using `Microsoft.Extensions.Configuration` where applicable, as `ConfigurationManager` behavior may differ or require the `System.Configuration.ConfigurationManager` NuGet package.