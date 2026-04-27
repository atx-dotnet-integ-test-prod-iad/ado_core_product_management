# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

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

Review the output for any warnings that could indicate deprecated APIs or packages that may cause runtime issues even if they do not produce build errors.

## 3. Review NuGet Package Versions

Open the `.csproj` file and check that all `<PackageReference>` entries reference versions that are compatible with the target framework. Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences introduced by the migration to cross-platform .NET.

## 5. Check for Platform-Specific API Usage

Even without build errors, some APIs that compiled successfully may behave differently or throw at runtime on non-Windows platforms. Use the .NET Upgrade Assistant compatibility analyzer or the Platform Compatibility Analyzer to identify any remaining platform-specific calls:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze
```

Pay particular attention to areas such as:
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions
- COM interop
- `System.Drawing` (GDI+)

## 6. Validate Runtime Behavior

Run the application directly and exercise its primary code paths:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

If the project is a library rather than an executable, write or run integration tests that exercise the public API surface.

## 7. Test on Target Platforms

If cross-platform support is a goal, run the application or tests on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that were not caught at compile time.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true -o ./publish
```

Replace `linux-x64` with your target runtime identifier (e.g., `win-x64`, `osx-x64`) as needed. Review the contents of the `./publish` directory to confirm all required assets are present before deploying.