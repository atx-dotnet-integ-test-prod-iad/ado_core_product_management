# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine by running:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts and update them as needed via the `.csproj` file or `dotnet add package`.

## 3. Build the Solution

Perform a clean build to confirm there are no residual or environment-specific issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Address any warnings that surface during the build, as some may indicate compatibility concerns that did not manifest as hard errors.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior has been preserved after migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated to determine whether they reflect a regression introduced during migration or a pre-existing issue.

## 5. Validate Runtime Behavior

Run the application and exercise its primary functionality manually or through integration tests. Pay particular attention to:

- **Database connectivity**, since ADO.NET connection strings and provider registrations may differ between .NET Framework and cross-platform .NET.
- **File path handling**, as `Path.Combine` and relative paths behave differently across operating systems.
- **Configuration loading**, since `System.Configuration.ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package on cross-platform .NET and reads from `app.config` rather than `appsettings.json` by default.

## 6. Check Platform-Specific API Usage

Run the .NET Compatibility Analyzer to surface any remaining platform-specific API calls that may compile but fail at runtime on non-Windows systems:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
dotnet build
```

Review any `CA1416` or similar platform compatibility warnings and replace or guard those APIs accordingly.

## 7. Test on Target Platforms

If cross-platform support is a goal, build and run the application on each intended operating system (Windows, Linux, macOS) to confirm consistent behavior:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent release build:

**Framework-dependent:**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Verify the contents of the `./publish` directory and confirm the application runs correctly from that output folder before deploying to the target environment.