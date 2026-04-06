# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not fully support your target framework. Consider replacing any packages flagged as incompatible with their modern equivalents.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings introduced at compile time:

```bash
dotnet clean
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to obsolete APIs or platform compatibility analyzers (CA1416, etc.).

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as failures may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime, particularly around areas such as:

- `System.Configuration` usage
- Windows-specific APIs
- Globalization and encoding defaults
- Reflection behavior changes

## 5. Validate Platform-Specific Code

Search the codebase for APIs that are Windows-only and may silently fail or throw on Linux/macOS:

- `Microsoft.Win32` registry access
- `System.Drawing` (GDI+)
- COM interop
- `System.Security.Permissions`

Use the .NET Compatibility Analyzer to surface these issues:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

## 6. Check Runtime Configuration

Review or create an `appsettings.json` or `runtimeconfig.json` if the project previously relied on `app.config` or `web.config`. The `System.Configuration.ConfigurationManager` package is available for backward compatibility if needed:

```xml
<PackageReference Include="System.Configuration.ConfigurationManager" Version="8.0.0" />
```

## 7. Smoke Test on Target Platforms

Run the application on each platform you intend to support (Windows, Linux, macOS) and verify core functionality behaves as expected:

```bash
dotnet run --configuration Release
```

Pay particular attention to file path separators, line endings, and culture-sensitive operations, as these can differ across platforms.

## 8. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent release build:

**Framework-dependent:**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish/linux-x64
```

Verify the output in the `./publish` directory runs correctly on the target machine.