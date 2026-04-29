# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this is consistent with any dependent or consuming projects in the solution.

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

If the solution contains test projects, execute them to verify that runtime behavior has not changed during the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework APIs and their cross-platform .NET equivalents.

## 4. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any remaining Windows-specific API calls that may compile successfully but fail at runtime on non-Windows platforms:

```bash
dotnet add package Microsoft.Windows.Compatibility
```

Alternatively, run the API compatibility analyzer:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

## 5. Validate NuGet Package Versions

Open the `.csproj` file and review all `<PackageReference>` entries. Confirm that each package version supports the target framework. Check [nuget.org](https://www.nuget.org) for any packages that may have been updated or replaced since the original project was written.

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that would not appear during compilation.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Or for a framework-dependent deployment:

```bash
dotnet publish --configuration Release
```

Review the contents of the `publish` output directory to confirm all required assets are present before deploying to the target environment.