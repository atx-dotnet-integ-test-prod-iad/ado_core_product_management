# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other .NET Framework monikers unless a multi-targeting scenario is intentional.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they are not hard errors.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in globalization, file path handling, or reflection behavior).

### 4. Check for Removed or Changed APIs
Even with a successful build, some APIs behave differently on cross-platform .NET. Review the code for usage of the following common problem areas:

- `System.Drawing` — requires the `System.Drawing.Common` NuGet package and has platform restrictions on non-Windows systems.
- `AppDomain` — some members are no longer supported.
- `BinaryFormatter` — disabled by default in .NET 5+; consider replacing with a supported serializer.
- Windows Registry access (`Microsoft.Win32.Registry`) — only functional on Windows.
- `Thread.Abort()` — throws `PlatformNotSupportedException` on cross-platform .NET.

### 5. Review NuGet Package Compatibility
Open the `.csproj` files and inspect all `<PackageReference>` entries. Verify each package has a version that supports the target framework by checking [NuGet.org](https://www.nuget.org). Packages that were built exclusively for .NET Framework may cause runtime failures even if they compile successfully.

### 6. Test on Target Platforms
If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a Windows-only build.

```bash
dotnet run --configuration Release
```

### 7. Publish a Release Build
Once validation is complete, produce a published output to confirm the deployment artifact is generated correctly:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to ensure all expected assemblies, configuration files, and assets are present.

### 8. Review Configuration Files
Check that any `App.config` or `Web.config` files have been migrated to `appsettings.json` or the appropriate .NET configuration model, as `System.Configuration.ConfigurationManager` has limited support and behavior differences on cross-platform .NET.