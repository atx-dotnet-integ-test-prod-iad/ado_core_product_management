# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework is set to the intended cross-platform version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly against the new target framework:

```bash
dotnet restore
```

Review the output for any dependency conflicts or packages that may have been replaced with newer equivalents during transformation.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet clean
dotnet build
```

Address any warnings that surface, particularly those related to deprecated APIs or platform compatibility.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test
```

Review test output carefully. Any failing tests may indicate behavioral differences between the legacy .NET Framework APIs and their cross-platform .NET equivalents.

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer to identify any remaining platform-specific API calls that may not behave consistently across operating systems. This can be enabled by adding the following to your `.csproj`:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

Rebuild after adding these properties and review any new diagnostics.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish -c Release -r <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value, such as `win-x64`, `linux-x64`, or `osx-x64`. Review the contents of the publish output folder before deploying to your target environment.