# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this matches the .NET SDK version installed on your machine by running:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly against the new target framework:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not fully support the target framework (NU1701 warnings in particular). These packages may still function but should be evaluated for newer alternatives.

## 3. Build the Solution

Perform a clean build to confirm there are no compile-time issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, especially those related to nullable reference types or obsolete APIs, as these can indicate areas of risk at runtime.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully. Failures after a framework migration often point to behavioral differences in APIs between .NET Framework and modern .NET.

## 5. Validate Platform-Specific Code

Search the codebase for any APIs that were Windows-specific in .NET Framework and may behave differently or be unavailable on Linux and macOS. Common areas to check include:

- `System.Windows.Forms` or `System.Drawing` usage
- Registry access (`Microsoft.Win32.Registry`)
- COM interop
- `AppDomain` usage beyond what is supported in modern .NET
- `System.Configuration.ConfigurationManager` (requires the `System.Configuration.ConfigurationManager` NuGet package)

Run the application on each target platform (Windows, Linux, macOS) if cross-platform support is a goal.

## 6. Review Removed APIs

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any API usage that has been removed in modern .NET. You can also run:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

This enables .NET analyzers that flag deprecated or unsupported API usage.

## 7. Test Runtime Behavior

Beyond compilation, exercise the main workflows of the application manually or through integration tests. Pay particular attention to:

- File I/O path separators (`\` vs `/`)
- Culture and encoding defaults, which differ between .NET Framework and modern .NET
- Reflection behavior, which is more restricted in modern .NET
- Thread and async behavior changes

## 8. Publish the Application

Once validation is complete, publish the application for your target environment:

**Framework-dependent deployment:**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained deployment (example for Linux x64):**
```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the output in the `./publish` directory runs correctly on the target machine.