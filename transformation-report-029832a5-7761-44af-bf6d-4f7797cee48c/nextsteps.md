# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-specific TFM such as `net472` or `net48`, update it accordingly.

---

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Verify that no warnings are being treated as errors and that all project references resolve correctly.

---

## 3. Run Existing Tests

If the solution contains test projects, execute them to confirm existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any test failures carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

---

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been replaced with cross-platform alternatives that behave differently at runtime. Review the code for usage of:

- `System.Data` providers (e.g., OLE DB, ODBC) — these have limited or no support on non-Windows platforms.
- Windows Registry access (`Microsoft.Win32.Registry`).
- COM interop or P/Invoke calls targeting Windows-specific libraries.
- `System.Drawing` — replaced by `System.Drawing.Common`, which requires additional configuration on Linux/macOS.

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package to surface any remaining platform compatibility issues.

---

## 5. Validate NuGet Package Compatibility

Open the `.csproj` file and review all `<PackageReference>` entries. Confirm that each package supports your target framework by checking the package page on [nuget.org](https://www.nuget.org). Packages that only list `net4x` targets may not function correctly.

---

## 6. Test on the Target Platform

If the goal is cross-platform execution (e.g., Linux or macOS), run the application on that operating system directly:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Then execute the published output on the target machine and observe runtime behavior.

---

## 7. Review Configuration Files

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables, as `System.Configuration.ConfigurationManager` has limited support in cross-platform .NET and may require the `System.Configuration.ConfigurationManager` NuGet package explicitly.

---

## 8. Deploy

Once validation is complete:

1. Publish the final build:
   ```bash
   dotnet publish --configuration Release --output ./publish
   ```
2. Copy the contents of the `./publish` directory to the target environment.
3. Run the application and confirm expected behavior matches the legacy version.