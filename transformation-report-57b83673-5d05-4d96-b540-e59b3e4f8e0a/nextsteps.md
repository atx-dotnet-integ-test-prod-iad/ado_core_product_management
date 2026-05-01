# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this aligns with the runtime environment you intend to deploy to.

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not cause build failures.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and compare behavior against the original .NET Framework version if available.

## 4. Check for Runtime Compatibility Issues

Some APIs behave differently or are unavailable in cross-platform .NET even if the code compiles. Pay attention to the following areas:

- **Registry access** (`Microsoft.Win32.Registry`): Not supported on Linux/macOS.
- **Windows Communication Foundation (WCF)**: Client-side is partially supported via `System.ServiceModel`; server-side is not supported natively.
- **`System.Drawing`**: Requires the `System.Drawing.Common` NuGet package and may have platform restrictions.
- **`AppDomain`**: Some members are no longer supported.
- **`Thread.Abort`**: Throws `PlatformNotSupportedException` in .NET 5+.

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to surface these issues.

## 5. Review NuGet Package Versions

Open the `.csproj` file and verify that all NuGet packages reference versions compatible with your target framework. Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update packages where appropriate, taking care to review changelogs for breaking changes.

## 6. Test on Target Platform

If the goal of the migration is cross-platform support, run the application on each intended platform (Windows, Linux, macOS) to surface any platform-specific runtime issues not caught during compilation.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate RID (e.g., `linux-x64`, `osx-x64`) based on your deployment environment. Use `--self-contained true` if you want to bundle the .NET runtime with the output.

## 8. Verify Output Artifacts

After publishing, confirm the output directory contains the expected binaries and that no legacy `.config` files (e.g., `app.config` transformed to `appsettings.json`) are missing or misconfigured.