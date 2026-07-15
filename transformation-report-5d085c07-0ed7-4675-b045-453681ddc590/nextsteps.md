# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build context:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility, as these can indicate subtle issues introduced during migration.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release
```

Review test results carefully. A passing build does not guarantee correct runtime behavior, so test coverage is important at this stage.

## 4. Verify Target Framework

Open each `.csproj` file and confirm that the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0`). Ensure consistency across all projects in the solution.

## 5. Check for Removed or Changed APIs

Some APIs available in .NET Framework are not present or have changed in cross-platform .NET. Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any remaining compatibility concerns at runtime.

## 6. Test on Target Platforms

Since the project is now cross-platform, validate it on each operating system you intend to support (Windows, Linux, macOS) by running the application and executing tests on each platform:

```bash
dotnet run --configuration Release
```

Pay particular attention to file path handling, line endings, and any platform-specific dependencies such as registry access or Windows-only libraries.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained true
```

Replace `<runtime-identifier>` with the appropriate value, for example:
- `win-x64` for Windows
- `linux-x64` for Linux
- `osx-x64` for macOS

Review the publish output directory to confirm all required assets are present before deploying.