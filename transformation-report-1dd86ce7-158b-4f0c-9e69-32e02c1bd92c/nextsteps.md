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

Review the output for any warnings about deprecated packages or packages that do not support the target framework. Replace any packages that only target `net4x` with their cross-platform equivalents where applicable.

## 3. Build the Solution

Perform a full build in Release configuration to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or platform compatibility analyzers (CA1416), as these can indicate runtime issues on non-Windows platforms.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as failures may indicate behavioral differences between .NET Framework and modern .NET (e.g., changes in `System.Data`, encoding defaults, or reflection behavior).

## 5. Validate Platform-Specific Code

Search the codebase for APIs that may not be supported on all platforms:

- `Registry` access (`Microsoft.Win32.Registry`)
- `System.Drawing` (requires `libgdiplus` on Linux/macOS)
- COM interop or P/Invoke calls
- `AppDomain.CreateDomain` (not supported in .NET Core+)
- `BinaryFormatter` (disabled by default in .NET 5+)

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` package to identify these issues programmatically.

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime-only issues that do not appear at compile time.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application for your target platform. For a self-contained deployment:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true
```

Replace `win-x64` with the appropriate runtime identifier (`linux-x64`, `osx-x64`, etc.) as needed. Review the contents of the `publish` output folder to confirm all required assets are present before distribution.