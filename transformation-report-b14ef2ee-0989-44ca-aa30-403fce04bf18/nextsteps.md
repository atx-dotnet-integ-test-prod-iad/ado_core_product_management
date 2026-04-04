# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless that is intentional for multi-targeting.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

### 4. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any APIs that are Windows-only or otherwise platform-restricted. You can also run:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Look for `CA1416` (platform compatibility) warnings in the output.

### 5. Review NuGet Package Versions
Open the `.csproj` files and verify that all NuGet package references are using versions compatible with your target framework. Check [nuget.org](https://www.nuget.org) for the latest stable versions if any packages appear outdated.

### 6. Validate Configuration Files
If the project previously used `app.config` or `web.config`, confirm that any necessary settings have been migrated to `appsettings.json` or environment-based configuration as appropriate for .NET.

### 7. Smoke Test the Application
Run the application locally and exercise its primary functionality to confirm that the runtime behavior matches expectations from the legacy version:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Address any runtime exceptions or unexpected behavior before considering the migration complete.

## Deployment

### 1. Publish the Application
Once validation is complete, publish the application for your target environment:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment (no .NET runtime required on the target machine):

```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) for your target platform.

### 2. Verify the Published Output
Inspect the `./publish` directory to confirm all expected assemblies, configuration files, and static assets are present before deploying to the target environment.