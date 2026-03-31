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

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not cause build failures.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior is consistent with the original legacy project:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Pay attention to any tests that were previously passing and now fail, as this may indicate behavioral differences between the old and new target frameworks.

## 4. Check for Removed or Changed APIs

Even without build errors, some APIs may behave differently in cross-platform .NET compared to .NET Framework. Review the following areas manually:

- **Database access**: If `AdoCore` implies ADO.NET usage, verify that all connection providers (e.g., `System.Data.SqlClient` vs `Microsoft.Data.SqlClient`) are explicitly referenced and functioning correctly.
- **Configuration**: Ensure any use of `ConfigurationManager` has been replaced with `Microsoft.Extensions.Configuration` if applicable.
- **File paths**: Confirm that any hardcoded path separators (`\`) have been replaced with `Path.Combine` or `Path.DirectorySeparatorChar` for cross-platform compatibility.
- **Platform-specific APIs**: Use the [.NET Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to identify any remaining platform-specific calls.

## 5. Test on Target Platform

If the goal is cross-platform support, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a Windows-only build.

```bash
dotnet run --configuration Release
```

## 6. Review NuGet Package Compatibility

Check that all NuGet dependencies are compatible with the target framework. Run the following to list packages and inspect for any that still target `net45`, `net472`, or similar legacy monikers:

```bash
dotnet list package
```

Replace any incompatible packages with their cross-platform equivalents where necessary.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate RID (e.g., `linux-x64`, `osx-x64`) based on your deployment environment. Review the contents of the `publish` output folder before deploying to confirm all required files are present.