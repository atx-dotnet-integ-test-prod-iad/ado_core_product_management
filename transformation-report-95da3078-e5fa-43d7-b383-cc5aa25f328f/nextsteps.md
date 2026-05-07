# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this aligns with the runtime available in your target environment.

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

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not block the build.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior is consistent with the original application:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Even without build errors, certain APIs that compiled successfully may behave differently or throw at runtime on non-Windows platforms. Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for such usage:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to:
- `System.Drawing` (requires `libgdiplus` on Linux/macOS or replacement with `SkiaSharp`)
- Windows Registry access (`Microsoft.Win32.Registry`)
- COM interop or P/Invoke calls targeting Windows-only libraries
- `System.Web` references (not available in .NET Core+)

## 5. Validate NuGet Package Compatibility

Open the `.csproj` file and review all `<PackageReference>` entries. Confirm that each package version supports your target framework. You can check compatibility on [nuget.org](https://www.nuget.org) or by running:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with cross-platform support.

## 6. Run the Application and Perform Functional Testing

Execute the application directly and perform manual or automated functional testing to confirm end-to-end behavior:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Focus testing on any database access, file I/O, and network operations, as these areas are most likely to surface runtime differences.

## 7. Review Configuration Files

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables as appropriate for .NET. Verify that connection strings and other environment-specific values are correctly loaded at runtime.

## 8. Publish the Application

Once validation is complete, publish the application for your target environment:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value for your target platform, for example:
- `win-x64` for Windows 64-bit
- `linux-x64` for Linux 64-bit
- `osx-x64` for macOS 64-bit

Review the contents of the publish output directory before deploying to confirm all required assets are present.