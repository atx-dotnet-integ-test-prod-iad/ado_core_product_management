# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). For example:

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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if the build succeeds.

## 3. Review NuGet Package Versions

Open the `.csproj` file and inspect all `<PackageReference>` entries. Ensure each package:
- Has a version compatible with your target framework.
- Is not a legacy Windows-only package that may have been carried over from the original project (e.g., older `System.Data` wrappers or COM interop packages).

Use the following command to check for outdated packages:

```bash
dotnet list package --outdated
```

Update packages as appropriate using:

```bash
dotnet add package <PackageName> --version <NewVersion>
```

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite to validate runtime behavior:

```bash
dotnet test --configuration Release --verbosity normal
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Validate Platform-Specific Code

Since this is a migration from a legacy project, manually review the codebase for any APIs that were available in .NET Framework but have changed or been removed in cross-platform .NET. Common areas to check include:

- `System.Web` usage — not available in .NET Core/.NET 5+.
- `AppDomain` APIs — partially available; some methods throw `PlatformNotSupportedException`.
- Registry access (`Microsoft.Win32.Registry`) — only functional on Windows.
- `BinaryFormatter` — deprecated and disabled by default in .NET 5+.
- WCF server-side components — not supported on cross-platform .NET without third-party libraries.

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining compatibility concerns.

## 6. Test on Target Operating Systems

If cross-platform support is a goal, run and validate the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear at build time.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

**Framework-dependent (requires .NET runtime installed on target machine):**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (bundles the runtime with the application):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Replace `linux-x64` with the appropriate runtime identifier for your target platform (e.g., `win-x64`, `osx-x64`, `linux-arm64`).

## 8. Verify Published Output

Navigate to the `./publish` directory and confirm all expected files are present. Run the published output directly to perform a final smoke test before deploying to the target environment.