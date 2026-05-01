# Next Steps

The solution has no build errors following the transformation. The steps below cover validation and deployment.

## 1. Review the Transformed Project File

Open `AdoCore.csproj` and confirm the following:

- The `<TargetFramework>` element targets a supported cross-platform .NET version, for example `net8.0`.
- Any remaining `<Reference>` elements that previously pointed to Windows-only assemblies (such as `System.Web` or `System.Windows.Forms`) have been removed or replaced with appropriate NuGet packages.
- NuGet package versions are current and compatible with the target framework.

## 2. Restore Dependencies

Run the following command from the solution root to confirm all dependencies resolve correctly:

```bash
dotnet restore
```

Resolve any warnings about deprecated or unlisted packages before proceeding.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings introduced by the restore step:

```bash
dotnet build --configuration Release
```

Review any warnings in the output, particularly those related to nullable reference types or obsolete API usage, as these can indicate areas that may cause runtime issues.

## 4. Run the Existing Test Suite

If the solution contains test projects, execute them to verify that behavior has not changed during transformation:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully. Failures may indicate behavioral differences between the legacy .NET Framework APIs and their cross-platform equivalents.

## 5. Perform Runtime Validation

- Run the application on each target platform (Windows, Linux, macOS) that the migration was intended to support.
- Exercise all major code paths, paying particular attention to areas that previously relied on Windows-specific features such as the registry, file path separators, or platform-specific interop.
- Confirm that connection strings, configuration files, and environment-specific settings load correctly on each platform.

## 6. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer to identify any remaining platform-specific API calls:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
dotnet build
```

Address any diagnostics reported by the analyzer before proceeding to deployment.

## 7. Publish the Application

Once validation is complete, publish the application for the intended target platform:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier for your target environment. Common values include `win-x64`, `linux-x64`, and `osx-x64`.

Review the contents of the publish output directory to confirm all required assets are present before deploying to the target environment.