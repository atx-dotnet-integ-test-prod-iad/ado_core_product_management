# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if they do not produce build errors.

## 3. Review NuGet Package Versions

Open the `.csproj` file and check that all `<PackageReference>` entries reference versions that are compatible with your target framework. You can check for outdated packages by running:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions available, particularly those that previously targeted .NET Framework.

## 4. Check for Removed or Changed APIs

Even without build errors, some APIs behave differently or have been removed in cross-platform .NET compared to .NET Framework. Pay particular attention to:

- `System.Data` and ADO.NET provider usage, since the project name suggests ADO-related functionality.
- Any database driver packages (e.g., `System.Data.SqlClient` should be replaced with `Microsoft.Data.SqlClient` if not already done).
- Any usage of `ConfigurationManager`, which requires the `System.Configuration.ConfigurationManager` NuGet package on cross-platform .NET.

## 5. Run Existing Tests

If a test project exists in the solution, execute the tests to verify runtime behavior:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may surface runtime incompatibilities not caught at compile time.

## 6. Perform Runtime Smoke Testing

Run the application and exercise its core functionality manually or through integration tests. Specifically for ADO.NET-related code:

- Verify that database connections open and close correctly.
- Verify that queries return expected results.
- Verify that transactions commit and roll back as expected.
- Check that connection strings are being read from the correct configuration source (e.g., `appsettings.json` instead of `app.config` or `web.config`).

## 7. Review Platform-Specific Code

Search the codebase for any platform-specific calls that may not behave correctly on non-Windows operating systems, such as:

- Windows registry access.
- Windows-specific file path formats.
- COM interop or P/Invoke calls.

Use `RuntimeInformation.IsOSPlatform()` guards where platform-specific code must be retained.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assemblies and configuration files are present before deploying to the target environment.