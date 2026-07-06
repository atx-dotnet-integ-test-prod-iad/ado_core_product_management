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

Check that all NuGet dependencies referenced in `AdoCore.csproj` are targeting compatible versions for your chosen .NET version. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework.

## 4. Check for Removed or Changed APIs

Review the code for any usage of APIs that were available in .NET Framework but have changed or been removed in cross-platform .NET. The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.UpgradeAssistant` tool can assist with this.

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze
```

## 5. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --verbosity normal
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET.

## 6. Validate Platform-Specific Behavior

Since this is a cross-platform migration, verify that any file I/O, path handling, or registry access has been updated to be platform-agnostic. Pay particular attention to:

- File path separators (`Path.Combine` should be used instead of hardcoded `\` or `/`)
- Any Windows-specific APIs (e.g., `Microsoft.Win32` namespace usage)
- Environment variable access that may differ across operating systems

## 7. Test on Target Platforms

Run the application on each operating system you intend to support (Windows, Linux, macOS) to confirm consistent behavior:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) as needed. Use `--self-contained true` if you want to bundle the .NET runtime with the output.