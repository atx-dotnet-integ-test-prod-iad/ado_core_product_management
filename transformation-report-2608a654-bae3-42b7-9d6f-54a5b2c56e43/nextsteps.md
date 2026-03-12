# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. Run the following to confirm your SDK version:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages that may need to be updated.

## 3. Build the Solution

Perform a full build in Release configuration to confirm there are no errors or warnings that were not present during the initial transformation check:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or obsolete API usage.

## 4. Run the Test Suite

If the solution contains test projects, execute all tests to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated before proceeding.

## 5. Validate Platform-Specific Code

Since this was a legacy project migrated to cross-platform .NET, manually review the codebase for any remaining Windows-specific APIs or dependencies, including:

- `Microsoft.Win32` registry access
- `System.Windows.Forms` or `System.Drawing` (GDI+) usage
- P/Invoke calls to Windows-only native libraries
- File path separators hardcoded as `\`

Replace or conditionally compile any such code to ensure it behaves correctly on all target platforms.

## 6. Check Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement. Pay attention to:

- File I/O operations and path handling
- Environment variable access
- Culture and encoding assumptions

Use `Path.Combine` and `Path.DirectorySeparatorChar` where applicable instead of hardcoded path strings.

## 7. Review NuGet Package Compatibility

Check that all referenced NuGet packages support the target framework. Use the following command to identify outdated packages:

```bash
dotnet list package --outdated
```

Update packages where newer versions provide .NET compatibility improvements.

## 8. Publish the Application

Once validation is complete, publish the application using the desired runtime identifier (RID):

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate RID for your target environment (e.g., `linux-x64`, `osx-x64`). Use `--self-contained true` if you want to bundle the .NET runtime with the output.

## 9. Verify Published Output

Navigate to the publish output directory and confirm all expected files are present. Run the published binary directly to verify it starts and behaves as expected in a production-like environment.