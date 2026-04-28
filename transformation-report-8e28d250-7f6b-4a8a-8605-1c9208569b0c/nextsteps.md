# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

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

Run a NuGet restore to confirm all packages resolve correctly under the new TFM:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not support the target framework or that have been replaced by inbox .NET APIs.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to obsolete APIs or platform-specific code paths.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify behavioral correctness after the migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee runtime correctness, so test coverage is important here.

## 5. Audit Platform-Specific Code

Search the codebase for APIs that were Windows-specific in the original .NET Framework project. Common areas to check include:

- `System.Data` and ADO.NET provider usage (relevant given the `AdoCore` project name)
- Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) client or server code
- `System.Drawing` (now requires the `System.Drawing.Common` NuGet package on non-Windows platforms)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to flag remaining compatibility concerns.

## 6. Validate ADO.NET Provider References

Since the project is named `AdoCore`, confirm that any database provider packages (e.g., `System.Data.SqlClient` or `Microsoft.Data.SqlClient`) are explicitly referenced and updated to their cross-platform NuGet versions:

```xml
<PackageReference Include="Microsoft.Data.SqlClient" Version="5.x.x" />
```

`System.Data.SqlClient` is not recommended for cross-platform use. Prefer `Microsoft.Data.SqlClient`.

## 7. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime platform incompatibilities that static analysis may not catch:

```bash
dotnet run --configuration Release
```

## 8. Review Output Artifacts

Confirm the build output in the `bin/Release/net8.0/` directory contains the expected assemblies and that no unintended framework-specific folders (e.g., `net472`) are present.

## 9. Publish the Application

Once validation is complete, publish the application for your target runtime:

**Framework-dependent (requires .NET runtime on target machine):**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (bundles the runtime):**
```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed.