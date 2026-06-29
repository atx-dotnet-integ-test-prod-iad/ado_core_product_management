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

Ensure there are no warnings that could indicate compatibility issues, such as deprecated APIs or platform-specific calls.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been silently replaced or may behave differently at runtime. Review the code for usage of:

- `System.Data` (ADO.NET) classes, since the project name suggests ADO usage — verify database provider packages (e.g., `Microsoft.Data.SqlClient`) are referenced instead of legacy `System.Data.SqlClient` where applicable.
- `ConfigurationManager` — this requires the `System.Configuration.ConfigurationManager` NuGet package on cross-platform .NET.
- Any Windows-only APIs (e.g., registry access, COM interop, WinForms/WPF) that may compile but fail at runtime on non-Windows platforms.

## 5. Validate NuGet Package Compatibility

Check that all referenced NuGet packages support the target framework. Run the following to identify any compatibility concerns:

```bash
dotnet list package --outdated
dotnet list package --deprecated
```

Update any outdated or deprecated packages to their current stable versions.

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

**Self-contained (bundles the runtime):**
```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed.

## 8. Review Output Artifacts

Inspect the contents of the `./publish` directory to confirm all expected assemblies, configuration files, and dependencies are present before deploying to the target environment.