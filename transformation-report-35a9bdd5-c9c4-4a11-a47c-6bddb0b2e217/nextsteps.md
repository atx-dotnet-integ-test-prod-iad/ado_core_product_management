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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Review NuGet Package Versions

Run the following command to check for outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework, particularly any that were previously targeting `.NET Framework`.

## 4. Check for Removed or Changed APIs

Review any usages of APIs that are known to have been removed or changed in cross-platform .NET. Common areas to inspect include:

- `System.Web` references (not available in cross-platform .NET)
- `AppDomain` usage
- Windows-specific registry or file path assumptions
- `BinaryFormatter` (deprecated and disabled by default in .NET 5+)

## 5. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET.

## 6. Validate Runtime Behavior on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to identify any platform-specific runtime issues that would not surface during a build.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

**Framework-dependent (requires .NET runtime installed on target machine):**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (bundles the runtime with the output):**
```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier for your target platform (e.g., `win-x64`, `osx-x64`, `osx-arm64`).

## 8. Review Output Artifacts

Inspect the contents of the `./publish` directory to confirm all expected assemblies, configuration files, and assets are present before deploying to the target environment.