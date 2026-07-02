# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Debug
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete APIs, as these may indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations from the legacy project:

```bash
dotnet test --configuration Release
```

Review test results carefully. A passing build does not guarantee correct runtime behavior, so test coverage is important at this stage.

## 4. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0`). Example:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

Ensure no projects are still referencing `net4x` or `netstandard` targets unintentionally.

## 5. Check Platform-Specific API Usage

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any remaining Windows-specific API calls that may compile successfully but fail at runtime on non-Windows platforms:

```bash
dotnet tool install -g dotnet-analyze
```

Pay particular attention to areas such as:
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions
- COM interop or P/Invoke calls

## 6. Run on Target Platforms

If cross-platform support is a goal, run and test the application on each intended platform (Linux, macOS, Windows) to surface any runtime-only issues:

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate RID for your environment (e.g., `win-x64`, `osx-x64`). Review the publish output directory to confirm all required assets are present before deploying.