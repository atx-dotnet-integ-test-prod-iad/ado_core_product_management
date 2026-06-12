# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-only TFM such as `net472` or `net48`, update it accordingly.

## 2. Restore and Build the Solution

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or platform-specific code paths that could cause runtime issues even if they do not produce build errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences in the new runtime or by platform-specific dependencies that need to be addressed.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been silently replaced or may behave differently on non-Windows platforms. Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for platform-specific calls:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <path-to-solution>
```

Pay particular attention to:
- `System.Drawing` (requires `libgdiplus` on Linux/macOS or replacement with `SkiaSharp`/`ImageSharp`)
- Windows Registry access (`Microsoft.Win32.Registry`)
- COM interop
- `System.Windows.Forms` or `System.Web` references

## 5. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` have versions compatible with the target framework. Open the `.csproj` and cross-reference each `<PackageReference>` against the package's supported frameworks on [nuget.org](https://www.nuget.org).

Replace any packages that only support .NET Framework with their cross-platform equivalents where necessary.

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime-only platform issues:

```bash
dotnet run --configuration Release
```

On Linux or macOS, watch for `PlatformNotSupportedException` or `DllNotFoundException` at runtime.

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime. For a self-contained deployment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true -o ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, `osx-arm64`, etc.) as needed. Review the contents of the `./publish` directory to confirm all required assets are present before deploying.