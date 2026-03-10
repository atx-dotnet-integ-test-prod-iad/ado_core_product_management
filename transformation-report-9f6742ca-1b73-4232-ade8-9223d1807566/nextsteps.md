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

Check that all NuGet dependencies referenced in `AdoCore.csproj` are targeting .NET-compatible versions. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework.

## 4. Run Existing Tests

If the solution contains test projects, execute the test suite to verify runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Pay close attention to any test failures that may indicate behavioral differences introduced during the migration.

## 5. Check for Platform-Specific Code

Search the codebase for any remaining usage of Windows-specific APIs (e.g., `System.Windows.Forms`, `Microsoft.Win32`, COM interop, or P/Invoke calls). These may compile successfully but fail at runtime on non-Windows platforms. Use the .NET Platform Compatibility Analyzer to assist:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

## 6. Validate Runtime Behavior

Run the application manually or through its entry point and exercise the primary workflows to confirm expected behavior:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Compare outputs against the known behavior of the original legacy project.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate RID (e.g., `linux-x64`, `osx-x64`) if targeting non-Windows platforms. Review the contents of the `publish` output directory to confirm all required assets are present before deployment.