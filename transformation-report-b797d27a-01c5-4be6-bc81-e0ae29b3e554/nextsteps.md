# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Runtime-Only Issues

Some issues do not surface at build time. Run the application and exercise its primary code paths:

```bash
dotnet run --configuration Release
```

Pay attention to:
- Any `PlatformNotSupportedException` at runtime, which may indicate use of Windows-only APIs.
- Reflection-based code that may behave differently under newer .NET versions.
- Any configuration or file path assumptions that are OS-specific.

## 5. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` have versions compatible with your target framework. You can use the following command to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions available that support your target framework.

## 6. Audit for Windows-Specific APIs

Use the .NET Compatibility Analyzer to identify any remaining platform-specific API usage. Add the following package if not already present:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the build warnings for `CA1416` (platform compatibility) analyzer messages.

## 7. Validate Configuration Files

Ensure that any `app.config` or `web.config` files have been migrated to `appsettings.json` or the appropriate .NET configuration model. Verify that connection strings, application settings, and environment-specific values are correctly loaded at runtime.

## 8. Publish the Application

Once validation is complete, publish the application for your target platform:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with your intended runtime identifier (e.g., `win-x64`, `osx-x64`). Review the output in the `publish` folder before deploying to the target environment.