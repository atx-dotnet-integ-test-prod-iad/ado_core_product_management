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

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they are not hard errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Runtime-Only Issues

Some issues do not surface at build time but appear at runtime. Pay particular attention to:

- **Reflection-based code**: Behavior can differ between .NET Framework and modern .NET.
- **Configuration files**: `app.config` and `web.config` are not fully supported. Migrate settings to `appsettings.json` where applicable.
- **Windows-only APIs**: If the project uses APIs such as the Registry, WMI, or certain `System.Drawing` features, verify they are either replaced with cross-platform alternatives or that the deployment target is explicitly Windows.

## 5. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` have versions that support your target framework. You can use the following command to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with cross-platform support.

## 6. Validate Database Connectivity (ADO Specific)

Given the project name `AdoCore`, it likely involves ADO.NET data access. Verify the following:

- Connection strings are correctly sourced from the new configuration system.
- Any `System.Data` usage is functioning correctly against your target database.
- If the legacy project used `System.Data.OleDb` or `System.Data.Odbc`, note that these have limited cross-platform support and may require the explicit NuGet packages `System.Data.OleDb` or `System.Data.Odbc`.

## 7. Run on Target Platform

If the goal is cross-platform deployment, run the application on the intended non-Windows platform (Linux or macOS) to surface any platform-specific issues:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Then execute the published output on the target machine and observe any runtime exceptions.

## 8. Deploy

Once validation is complete, publish the final output:

```bash
dotnet publish --configuration Release --output ./publish
```

Copy the contents of the `./publish` directory to the target environment and run the application.