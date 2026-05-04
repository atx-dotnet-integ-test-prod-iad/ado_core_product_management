# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy the migrated project.

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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Platform-Specific Code

Search the codebase for APIs that were Windows-specific in the legacy .NET Framework project. Common areas to inspect include:

- `System.Windows.Forms` or `System.Web` references
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions (e.g., backslashes, drive letters)
- `System.Drawing` (requires the `System.Drawing.Common` NuGet package on non-Windows platforms)

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to assist with this review.

## 5. Review NuGet Package Compatibility

Open the `.csproj` files and review all `<PackageReference>` entries. Confirm that each package targets a compatible version for your chosen .NET version. You can check compatibility at [nuget.org](https://www.nuget.org) or by running:

```bash
dotnet list package --outdated
```

Update any outdated or incompatible packages accordingly.

## 6. Validate Runtime Behavior

Run the application locally on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement. Pay attention to:

- File I/O operations and path separators
- Environment variable usage
- Culture and encoding assumptions

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# Framework-dependent deployment
dotnet publish --configuration Release --output ./publish

# Self-contained deployment for a specific platform
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files are present before deploying to the target environment.