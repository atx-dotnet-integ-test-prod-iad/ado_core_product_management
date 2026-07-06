# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this aligns with the runtime environment you intend to deploy to.

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

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not block the build.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences in the new runtime or by test setup issues.

## 4. Check for Removed or Changed APIs

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.ApiCompat` tooling to identify any APIs that were available in the legacy framework but have been removed or altered in the target framework. Pay particular attention to:

- `System.Web` dependencies (not available in .NET Core/.NET 5+)
- Windows-only APIs if cross-platform support is required
- Any reflection-based code that may behave differently

## 5. Review NuGet Package Versions

Open the `.csproj` file and review all `<PackageReference>` entries. Ensure each package:

- Supports the target framework
- Is on a current and maintained version
- Does not have known vulnerabilities (run `dotnet list package --vulnerable`)

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

## 6. Validate Runtime Behavior

Run the application locally and exercise the primary workflows manually or through integration tests. Confirm that:

- Database connections function correctly
- Any file I/O uses cross-platform path handling (`Path.Combine` rather than hardcoded separators)
- Configuration is loaded correctly (e.g., `appsettings.json` rather than `app.config` or `web.config` where applicable)

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) if deploying to a non-Windows environment. Review the contents of the `publish` output directory before deploying.