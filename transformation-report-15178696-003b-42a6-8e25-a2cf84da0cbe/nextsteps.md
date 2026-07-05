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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if they do not produce build errors.

## 3. Review NuGet Package Versions

Open the `.csproj` file and check that all `<PackageReference>` entries reference versions compatible with your target framework. Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions available, particularly those that previously targeted .NET Framework.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release
```

Address any test failures by reviewing API differences between .NET Framework and modern .NET, such as changes in `System.Data`, `System.Configuration`, or threading behavior.

## 5. Check for Runtime Configuration

If the original project relied on `app.config` or `web.config`, verify that the relevant settings have been migrated to `appsettings.json` or environment variables, as `System.Configuration.ConfigurationManager` behavior may differ on cross-platform .NET.

## 6. Validate Platform-Specific Code

Since this is a cross-platform migration, review any code that previously relied on Windows-specific APIs, such as:

- Windows Registry access (`Microsoft.Win32.Registry`)
- COM interop
- Windows-specific file path assumptions (backslashes, drive letters)
- `System.Drawing` (requires the `System.Drawing.Common` package and may have platform limitations)

Test the application on the target operating systems (Linux, macOS) if cross-platform support is a requirement.

## 7. Perform Functional Smoke Testing

Run the application manually and exercise the primary workflows to confirm that behavior matches the original .NET Framework version. Pay particular attention to:

- Database connectivity (ADO.NET connection strings and provider behavior)
- Exception handling paths
- Any reflection-based code

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required assets and dependencies are present before deploying to the target environment.