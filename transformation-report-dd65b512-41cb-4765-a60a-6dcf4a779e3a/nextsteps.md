# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this aligns with the runtime available in your target environment.

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

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Pay close attention to any tests that interact with data access or ADO.NET-specific functionality, as these are the most likely areas to exhibit behavioral differences after migration.

## 4. Validate ADO.NET Functionality

Since this project is named `AdoCore`, it likely contains data access logic. Manually verify the following:

- Connection strings are correctly configured for the target environment, particularly if they were previously stored in `app.config` or `web.config`. In .NET, `appsettings.json` is the standard configuration file.
- Any use of `System.Data` types such as `DataSet`, `DataTable`, `SqlConnection`, and `SqlCommand` should be tested against a live or test database instance.
- If `ConfigurationManager` was used in the original project, confirm it has been replaced with `Microsoft.Extensions.Configuration` or that the `System.Configuration.ConfigurationManager` NuGet package has been added if backward compatibility was chosen.

## 5. Check for Removed or Changed APIs

Run the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.ApiCompat` tool to surface any API usage that may compile but behave differently at runtime:

```bash
dotnet tool install -g dotnet-apicompat
```

Alternatively, review the [.NET breaking changes documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/breaking-changes) for the version you migrated from and to.

## 6. Review NuGet Package Versions

Open the `.csproj` file and confirm all NuGet packages reference versions compatible with your target framework. Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update packages where appropriate, particularly any that previously targeted .NET Framework.

## 7. Test on Target Operating System

If cross-platform support is a goal, run the application on each target operating system (Windows, Linux, macOS) to identify any platform-specific issues such as:

- File path separator differences
- Windows-only APIs (e.g., registry access, certain `System.Drawing` features)
- Case sensitivity in file system operations on Linux

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory and confirm all required assets, configuration files, and dependencies are present before deploying to the target environment.