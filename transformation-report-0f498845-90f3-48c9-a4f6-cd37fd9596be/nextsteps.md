# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Review NuGet Package Versions

Check that all NuGet dependencies referenced in `AdoCore.csproj` are targeting compatible versions for your chosen .NET version. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any outdated packages using:

```bash
dotnet add package <PackageName> --version <NewVersion>
```

## 4. Run Existing Tests

If a test project exists in the solution, execute the test suite to verify runtime behavior matches expectations from the legacy project:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Even without build errors, certain APIs that compiled successfully may not behave correctly or may throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Review usage of the following common problem areas:

- `System.Drawing` (use a cross-platform alternative such as `SkiaSharp` if needed)
- `Microsoft.Win32` registry APIs
- Windows Communication Foundation (WCF) client/server code
- `AppDomain` and remoting APIs

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to surface any remaining compatibility concerns.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (Windows, Linux, macOS) to catch any platform-specific runtime issues not surfaced during the build.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

**Framework-dependent (requires .NET runtime on target machine):**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (bundles the runtime):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (e.g., `win-x64`, `osx-x64`) as needed.

## 8. Verify Published Output

Navigate to the `./publish` directory and confirm the expected binaries and configuration files are present before deploying to the target environment.