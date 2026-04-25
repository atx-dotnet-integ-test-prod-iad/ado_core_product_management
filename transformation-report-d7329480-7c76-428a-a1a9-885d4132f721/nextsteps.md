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

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check NuGet Package Compatibility

Review all NuGet package references in `AdoCore.csproj` and any other projects. Ensure each package supports the target framework. You can check compatibility on [nuget.org](https://www.nuget.org). Replace any packages that only supported .NET Framework with their cross-platform equivalents where necessary.

## 5. Review Removed or Changed APIs

Some .NET Framework APIs are not available or behave differently in cross-platform .NET. Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the [Platform Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to identify any remaining problem areas at runtime.

Common areas to check:
- `System.Data` and ADO.NET provider usage (relevant given the `AdoCore` project name)
- Database driver packages (e.g., ensure you are using `Microsoft.Data.SqlClient` instead of `System.Data.SqlClient` if applicable)
- Configuration and connection string handling

## 6. Test on Target Platforms

Since the goal is cross-platform support, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific issues:

```bash
dotnet run --configuration Release
```

Pay particular attention to file path handling, line endings, and any platform-specific library dependencies.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` flag and `--self-contained` option based on your deployment requirements. Published output will be placed in the `bin/Release/<tfm>/<rid>/publish/` directory.