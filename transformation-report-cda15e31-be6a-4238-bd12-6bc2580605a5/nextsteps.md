# Next Steps

The transformation appears to have completed successfully. No build errors were reported across any of the projects in the solution. Below are recommended steps to validate and deploy the migrated project.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`). For example:

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

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not cause build failures.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Runtime-Only Issues

Some issues do not surface at build time but appear at runtime. Pay attention to the following areas:

- **Reflection-based code**: Behavior differences may exist between .NET Framework and modern .NET.
- **Configuration**: `System.Configuration.ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package if used. Verify `app.config` or `web.config` settings have been migrated to `appsettings.json` where appropriate.
- **WCF or Remoting**: These are not fully supported on cross-platform .NET. If any such dependencies exist, verify they have been replaced with supported alternatives.
- **Windows-specific APIs**: If the application is expected to run on Linux or macOS, audit any P/Invoke calls or Windows-only APIs (e.g., registry access, Windows identity).

## 5. Review NuGet Package Compatibility

Check that all NuGet packages referenced in the project are compatible with the target framework. You can use the following command to inspect outdated or potentially incompatible packages:

```bash
dotnet list package --outdated
```

Replace any packages that target only `net4x` with their modern equivalents where available.

## 6. Validate Application Output

Run the application directly and exercise its primary functionality:

```bash
dotnet run --configuration Release --project ./AdoCore/AdoCore.csproj
```

Confirm that outputs, database interactions, file I/O, and any external service calls behave as expected.

## 7. Publish the Application

Once validation is complete, publish the application for the target platform:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false --output ./publish
```

Adjust the `--runtime` flag (`linux-x64`, `osx-x64`, etc.) based on your deployment target. Use `--self-contained true` if the target machine does not have the .NET runtime installed.

## 8. Verify Published Output

Navigate to the publish output directory and confirm all expected files are present, including configuration files, static assets, and dependencies. Run the published executable directly to perform a final smoke test before deploying to the target environment.