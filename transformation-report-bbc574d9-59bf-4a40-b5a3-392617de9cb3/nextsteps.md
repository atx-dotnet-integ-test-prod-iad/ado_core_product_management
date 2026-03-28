# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). For example:

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

Check that all NuGet dependencies referenced in `AdoCore.csproj` are compatible with your target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions available, particularly those that previously targeted .NET Framework.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate runtime behavioral differences between .NET Framework and modern .NET.

## 5. Check for Removed or Changed APIs

Even without build errors, some APIs behave differently or have been removed in modern .NET. Review the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) output or run the following analyzer tool to surface any potential runtime issues:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <solution-file>.sln
```

Pay particular attention to:
- `System.Web` usages (not available in modern .NET)
- `AppDomain` APIs with limited support
- Reflection-based code that may behave differently
- Configuration system changes (`System.Configuration` vs `Microsoft.Extensions.Configuration`)

## 6. Test Application Behavior at Runtime

Run the application and exercise its primary workflows manually or through integration tests. Confirm that:
- Database connections (if any ADO.NET usage is present, given the project name `AdoCore`) function correctly
- Connection strings are correctly sourced from the new configuration system
- Any platform-specific behavior (file paths, encoding, etc.) works as expected on the target OS

## 7. Validate on Target Platform

If the goal is cross-platform support, test the application explicitly on each target operating system (Windows, Linux, macOS) to surface any platform-specific issues:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate RID (e.g., `linux-x64`, `osx-x64`) as needed. Review the output in the `publish` folder before deploying to the target environment.