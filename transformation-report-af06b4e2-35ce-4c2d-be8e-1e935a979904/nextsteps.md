# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm the no-error state is consistent across all configurations:

```bash
dotnet build --configuration Release
```

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and modern .NET (e.g., changes in globalization, reflection, or threading behavior).

### 5. Check for Runtime-Only Issues
Some issues do not surface at build time. Pay attention to the following areas at runtime:

- **Globalization**: Modern .NET uses ICU libraries by default instead of NLS. If the application relies on culture-specific string comparisons or formatting, test those code paths explicitly. You can revert to NLS behavior by adding the following to `runtimeconfig.json` or the `.csproj` if needed:
  ```xml
  <ItemGroup>
    <RuntimeHostConfigurationOption Include="System.Globalization.UseNls" Value="true" />
  </ItemGroup>
  ```
- **Reflection**: Some reflection APIs have changed or been restricted. Exercise any code paths that use `Assembly.LoadFrom`, `Type.GetType`, or dynamic invocation.
- **Configuration**: If the project previously used `System.Configuration` (`app.config` / `web.config`), confirm it has been migrated to `Microsoft.Extensions.Configuration` or that the `System.Configuration.ConfigurationManager` NuGet package has been added.
- **Windows-specific APIs**: If the project targets `net8.0` (non-Windows), any calls to Windows-only APIs (registry, WinForms, COM interop, etc.) will throw `PlatformNotSupportedException` at runtime even though they compile. Add the `<PlatformTarget>` or use runtime guards (`OperatingSystem.IsWindows()`) where necessary.

### 6. Review Removed APIs
Cross-reference the codebase against the [.NET Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) and the official [breaking changes documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/breaking-changes) for the version you are targeting. The `Microsoft.DotNet.Analyzers.Compatibility` NuGet package can assist with this inside the IDE.

### 7. Publish the Application
Once validation is complete, produce a published output:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment (no .NET runtime required on the target machine):

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (`linux-x64`, `osx-x64`, etc.) for your target platform.

### 8. Smoke Test the Published Output
Run the published binary directly from the `./publish` directory on a clean machine (or a machine without the .NET SDK installed, if self-contained) to confirm the application starts and operates correctly outside of a development environment.