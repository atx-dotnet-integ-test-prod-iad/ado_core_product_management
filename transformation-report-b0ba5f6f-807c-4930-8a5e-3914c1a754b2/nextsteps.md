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

If the solution contains test projects, execute them to verify that runtime behavior has not changed after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Removed or Changed APIs

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` compatibility tooling to identify any API usage that may compile successfully but behave differently at runtime. Pay particular attention to:

- `System.Web` references (not available in cross-platform .NET)
- Windows-specific APIs (e.g., registry access, WCF server-side, Windows Identity)
- `AppDomain`, `BinaryFormatter`, or `Remoting` usage

## 5. Review NuGet Package Compatibility

Inspect all NuGet dependencies in `AdoCore.csproj` and confirm each package supports the target framework. You can check compatibility on [nuget.org](https://www.nuget.org) or by reviewing the `lib` folders inside each `.nupkg` file.

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with cross-platform support.

## 6. Test on Target Operating System

If the intent is to run on Linux or macOS, execute the application on that operating system explicitly. Some issues (file path casing, line endings, platform-specific APIs) will only surface at runtime on a non-Windows system.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

**Framework-dependent (requires .NET runtime installed on target machine):**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (bundles the runtime):**
```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed.

## 8. Validate the Published Output

Navigate to the `./publish` directory and run the output directly to confirm the published artifact functions correctly before deploying to the target environment.

```bash
cd ./publish
dotnet AdoCore.dll
```

Or, if published as a self-contained executable:

```bash
./AdoCore
```