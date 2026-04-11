# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
  </PropertyGroup>
</Project>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Removed or Changed APIs

Some APIs available in .NET Framework are not present or have changed in cross-platform .NET. Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` compatibility shims if runtime errors surface during testing.

Run the API compatibility check:

```bash
dotnet tool install -g dotnet-apicompat
```

## 5. Validate Runtime Behavior

Execute the application and exercise its primary code paths. Pay particular attention to:

- **File system paths**: Cross-platform .NET uses forward slashes on Linux/macOS. Replace any hardcoded backslashes with `Path.Combine` or `Path.DirectorySeparatorChar`.
- **Registry access**: `Microsoft.Win32.Registry` is Windows-only. If the code uses the registry, guard it with runtime OS checks (`RuntimeInformation.IsOSPlatform`).
- **Database connectivity**: If `AdoCore` implies ADO.NET usage, verify that the database driver NuGet packages (e.g., `Microsoft.Data.SqlClient`, `Npgsql`) are the cross-platform compatible versions.

## 6. Review NuGet Package Versions

Open the `.csproj` file and confirm all NuGet packages reference versions that support your target framework:

```bash
dotnet list package --outdated
```

Update any outdated packages that have cross-platform compatible releases.

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment target. A full list of runtime identifiers is available in the [Microsoft RID catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).

## 8. Verify Output Artifacts

After publishing, navigate to the output directory (typically `bin/Release/net8.0/publish/`) and confirm all expected assemblies, configuration files, and dependencies are present before deploying to the target environment.