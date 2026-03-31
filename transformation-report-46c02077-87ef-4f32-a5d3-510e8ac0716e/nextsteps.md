# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Review NuGet Package Versions

Check that all NuGet dependencies referenced in `AdoCore.csproj` are targeting compatible versions for your chosen .NET version. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 5. Check for Platform-Specific API Usage

Since this was a legacy project migration, review the codebase for any remaining Windows-specific APIs (e.g., `System.Windows.Forms`, `Microsoft.Win32`, or P/Invoke calls targeting Windows DLLs). Use the .NET Upgrade Assistant compatibility analyzer or the following command to check for platform compatibility warnings:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Address any `CA1416` platform compatibility warnings that appear.

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) to confirm consistent runtime behavior:

```bash
dotnet run --configuration Release
```

Pay particular attention to file path handling, line endings, and any environment-specific configuration that may differ across platforms.

## 7. Publish the Application

Once validation is complete, publish the application for your target platform(s). For a self-contained deployment:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
dotnet publish --configuration Release --runtime osx-x64 --self-contained true
```

For a framework-dependent deployment (requires .NET runtime installed on the target machine):

```bash
dotnet publish --configuration Release
```

Review the output in the `publish` folder to confirm all required files are present before distributing.