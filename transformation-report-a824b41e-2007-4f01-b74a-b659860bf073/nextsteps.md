# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`).

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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and trace them back to API or behavioral differences between the legacy .NET Framework and the new .NET runtime.

## 4. Check for Runtime Compatibility Issues

Even with a clean build, certain APIs behave differently or are unavailable at runtime on cross-platform .NET. Pay attention to the following areas:

- **Registry access** (`Microsoft.Win32.Registry`): Not available on Linux/macOS without the `Microsoft.Win32.Registry` NuGet package.
- **Windows Communication Foundation (WCF)**: Server-side WCF is not supported; consider `CoreWCF` as a replacement.
- **`System.Web` dependencies**: These are not available in cross-platform .NET. Migrate to `Microsoft.AspNetCore` equivalents if applicable.
- **`AppDomain`**: Some members are no longer supported and will throw `PlatformNotSupportedException`.
- **`BinaryFormatter`**: Disabled by default in .NET 5+. Replace with a supported serialization mechanism such as `System.Text.Json` or `System.Runtime.Serialization`.

## 5. Review NuGet Package Versions

Open the `.csproj` file and verify that all NuGet packages reference versions compatible with your target framework. Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update packages where appropriate, and check each package's release notes for breaking changes.

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a Windows-only build.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

**Framework-dependent (requires .NET runtime installed on target machine):**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (bundles the runtime with the application):**
```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier for your target environment (e.g., `win-x64`, `osx-x64`, `osx-arm64`).

## 8. Validate the Published Output

Navigate to the publish output directory and run the application directly to confirm it executes correctly from the published artifacts before deploying to the target environment.