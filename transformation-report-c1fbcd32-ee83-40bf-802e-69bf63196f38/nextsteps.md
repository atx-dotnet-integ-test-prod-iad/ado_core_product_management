# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). For example:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that could not be resolved.

## 3. Build the Solution

Perform a full build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types, deprecated APIs, or platform compatibility.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review all test results and investigate any failures. Pay particular attention to tests that cover platform-specific behavior, as these are the most likely areas to be affected by a cross-platform migration.

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer to identify any remaining platform-specific API calls that may not be flagged as build errors but could cause runtime failures on non-Windows platforms:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Review any analyzer warnings and replace platform-specific APIs with cross-platform alternatives where applicable.

## 6. Validate Runtime Behavior

Run the application directly to confirm it behaves as expected at runtime:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

If the project is a library rather than an executable, create a small console application or use the existing test suite to exercise the core functionality.

## 7. Check Configuration and File Paths

Review any hardcoded file paths, registry access, or Windows-specific configuration patterns within the codebase. Replace backslash path separators with `Path.Combine` or forward slashes to ensure cross-platform compatibility.

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime. The following example publishes a self-contained executable for Linux:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier for your target environment (e.g., `win-x64`, `osx-x64`, `linux-arm64`). Review the output in the `publish` folder before deploying.