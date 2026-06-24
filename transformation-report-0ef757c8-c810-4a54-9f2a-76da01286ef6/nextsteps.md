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

Update packages where appropriate, then rebuild to confirm no new errors are introduced.

## 4. Run Existing Tests

If the solution contains test projects, execute the test suite to verify runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences between the legacy .NET Framework APIs and their cross-platform .NET equivalents.

## 5. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been carried over that behave differently or are unsupported on non-Windows platforms. Use the .NET Compatibility Analyzer or review the Microsoft API compatibility documentation for any APIs used in `AdoCore` that are known to have platform-specific behavior (e.g., registry access, Windows-specific file paths, COM interop).

You can enable the platform compatibility analyzer by adding the following to your `.csproj`:

```xml
<PropertyGroup>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <AnalysisMode>All</AnalysisMode>
</PropertyGroup>
```

## 6. Test on Target Platform

If the goal is cross-platform support, run and test the application on each intended operating system (e.g., Linux, macOS) to surface any runtime issues that static analysis may not catch:

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier for your environment (e.g., `win-x64`, `osx-x64`). Review the contents of the `publish` output folder before deploying to confirm all required assets are present.