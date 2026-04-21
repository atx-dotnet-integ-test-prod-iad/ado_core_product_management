# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net6.0`, `net7.0`, or `net8.0`):

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

Ensure there are no warnings that could indicate compatibility issues, such as deprecated APIs or platform-specific calls.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs that compiled successfully may throw at runtime on non-Windows platforms. Review the code for usage of:

- `Microsoft.Win32` registry APIs
- `System.Windows.Forms` or `System.Drawing` (GDI+)
- COM interop or P/Invoke calls targeting Windows-only native libraries
- `AppDomain` APIs with limited cross-platform support

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package to identify any remaining concerns.

## 5. Run the Application on Target Platforms

Execute the application on each platform you intend to support (Windows, Linux, macOS) to catch any runtime-only issues:

```bash
dotnet run --configuration Release
```

If targeting a specific runtime, use the `--runtime` flag:

```bash
dotnet run --configuration Release --runtime linux-x64
```

## 6. Publish a Self-Contained or Framework-Dependent Build

Once runtime validation is complete, publish the application for your target environment.

**Framework-dependent:**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Review the contents of the `./publish` directory to confirm all required assets and dependencies are present.

## 7. Review NuGet Package Compatibility

Confirm that all NuGet packages referenced in `AdoCore.csproj` have versions compatible with your target framework. Packages that were built for .NET Framework may have limited functionality or require replacement with their .NET-compatible equivalents. You can check compatibility on [nuget.org](https://www.nuget.org).