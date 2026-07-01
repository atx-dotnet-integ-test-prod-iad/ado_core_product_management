# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version you have installed. Run the following to confirm your SDK version:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a full NuGet restore to ensure all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any dependency warnings, particularly around packages that may have been resolved to older or incompatible versions.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during the build, as some warnings in cross-platform .NET can indicate runtime issues even when the build succeeds.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify behavioral correctness after the migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Failures here may indicate platform-specific behavior differences between .NET Framework and cross-platform .NET, such as changes in:

- `System.Data` behavior
- ADO.NET provider availability
- File path handling (`Path.DirectorySeparatorChar`)
- Culture and encoding defaults

## 5. Validate ADO.NET Provider Compatibility

Since the project is named `AdoCore`, it likely relies on ADO.NET data access. Verify the following:

- Any database drivers (e.g., `System.Data.SqlClient`, `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) are referenced as NuGet packages compatible with your target TFM.
- `System.Data.OleDb` and `System.Data.Odbc` are available on Windows only. If the project uses these, cross-platform support will be limited unless alternatives are introduced.
- Connection string formats and provider factory registrations behave as expected under the new runtime.

## 6. Check for Removed or Changed APIs

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any API usage that may have been removed or changed:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <path-to-solution>
```

Pay particular attention to any APIs flagged under `System.Data`, `System.Configuration`, or `System.Security`.

## 7. Review `app.config` / `web.config` Usage

Cross-platform .NET does not support `app.config` in the same way as .NET Framework. If the project reads configuration from these files, migrate the relevant settings to `appsettings.json` using `Microsoft.Extensions.Configuration`:

```csharp
var config = new ConfigurationBuilder()
    .AddJsonFile("appsettings.json")
    .Build();
```

## 8. Manual Smoke Testing

Run the application manually and exercise the primary data access paths to confirm end-to-end functionality:

```bash
dotnet run --configuration Release
```

Verify that database connections open successfully, queries return expected results, and no runtime exceptions are thrown in paths that were not covered by automated tests.

## 9. Publish the Application

Once validation is complete, publish the application for your target platform:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate RID, for example:

- `win-x64`
- `linux-x64`
- `osx-x64`

Review the publish output directory to confirm all required assemblies and configuration files are present before deploying to the target environment.