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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

## 3. Review NuGet Package Versions

Check that all NuGet dependencies referenced in `AdoCore.csproj` are compatible with your target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions available, particularly those that were previously targeting .NET Framework.

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Address any test failures before proceeding. Pay particular attention to tests covering database access, file I/O, or platform-specific behavior, as these areas are most commonly affected by cross-platform migrations.

## 5. Check for Platform-Specific Code

Search the codebase for APIs that may behave differently across operating systems. Common areas to review include:

- File path separators (`\` vs `/`) — use `Path.Combine` and `Path.DirectorySeparatorChar` where applicable.
- Registry access (`Microsoft.Win32.Registry`) — not available on Linux/macOS.
- Windows-specific authentication or security APIs.
- `System.Drawing` — requires additional native dependencies on non-Windows platforms.

## 6. Validate Runtime Behavior

Run the application in your target environment and exercise the primary workflows manually or through integration tests. Confirm that:

- Database connections (given the `AdoCore` project name implies ADO.NET usage) are established correctly.
- Connection strings are correctly configured for the target environment.
- Any `DbProviderFactory` or provider registration that was previously handled via `app.config`/`web.config` is now handled in code or via `appsettings.json`, since .NET does not automatically load provider factories from configuration files the way .NET Framework did.

## 7. Configuration Migration

If the project previously relied on `app.config` or `web.config`, ensure that settings have been migrated to `appsettings.json` or environment variables. Add the `Microsoft.Extensions.Configuration` packages if not already present:

```bash
dotnet add package Microsoft.Extensions.Configuration
dotnet add package Microsoft.Extensions.Configuration.Json
```

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory and confirm all required runtime files and dependencies are present before deploying to the target environment.