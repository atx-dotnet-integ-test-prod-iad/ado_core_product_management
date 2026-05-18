# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework is set to the intended cross-platform version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly against the new target framework:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version mismatches.

## 3. Build the Solution

Perform a clean build to confirm there are no issues beyond what was reported:

```bash
dotnet clean
dotnet build
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete APIs, as these can indicate compatibility concerns.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test
```

Review test output carefully. Any failures that were not present in the original project indicate regressions introduced during migration.

## 5. Validate Platform-Specific Behavior

If `AdoCore` contains any code that previously relied on Windows-specific APIs (such as `System.Data` providers, registry access, or Windows authentication), test the application on each target platform (Windows, Linux, macOS) to confirm correct behavior.

Run the application directly to observe runtime behavior:

```bash
dotnet run --project AdoCore.csproj
```

## 6. Review Removed or Changed APIs

Check for any use of APIs that have changed behavior between .NET Framework and modern .NET. Common areas to inspect include:

- `System.Data` and ADO.NET provider configurations
- `ConfigurationManager` (replaced by `Microsoft.Extensions.Configuration`)
- `AppDomain` usage
- Serialization via `BinaryFormatter` (removed in .NET 9)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining compatibility issues.

## 7. Publish the Application

Once validation is complete, publish the application for your target environment:

```bash
dotnet publish -c Release -r <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value, for example `win-x64`, `linux-x64`, or `osx-x64`. Review the contents of the publish output directory before deploying.