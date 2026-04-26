# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-only TFM such as `net472` or `net48`, update it accordingly.

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or incompatible packages and update them using:

```bash
dotnet add package <PackageName>
```

## 3. Build the Solution

Perform a full build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or platform compatibility analyzers (CA1416), as these can indicate code paths that will not function correctly on non-Windows platforms.

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review all test results and investigate any failures before proceeding.

## 5. Validate Platform-Specific Code

Since this is a migration to cross-platform .NET, check the codebase for any APIs that are Windows-specific. Common areas to inspect include:

- `Microsoft.Win32` registry access
- `System.Windows.Forms` or `System.Drawing` references
- COM interop or P/Invoke calls targeting Windows DLLs
- `Environment.SpecialFolder` paths that behave differently across operating systems

Use the .NET Compatibility Analyzer output during the build step above to locate these. Where necessary, add platform guards:

```csharp
if (OperatingSystem.IsWindows())
{
    // Windows-specific logic
}
```

## 6. Test on Target Platforms

Run and validate the application on each platform you intend to support (Linux, macOS, Windows):

```bash
dotnet run --configuration Release
```

Confirm that file paths, line endings, and environment variables behave as expected on each target OS.

## 7. Publish the Application

Once validation is complete, publish the application for your target runtime. For a self-contained deployment targeting Linux x64 as an example:

```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

For a framework-dependent deployment:

```bash
dotnet publish -c Release -o ./publish
```

Review the contents of the `./publish` directory and verify all required files and dependencies are present before distributing.