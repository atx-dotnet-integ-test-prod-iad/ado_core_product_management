# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command to ensure all NuGet packages are properly restored:

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

Address any warnings that appear, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release
```

Review test output carefully. A successful build does not guarantee correct runtime behavior, especially after a cross-platform migration.

## 4. Verify Platform-Specific Behavior

Cross-platform migrations can introduce subtle runtime differences. Manually verify the following:

- **File paths**: Ensure no hardcoded Windows-style paths (e.g., `C:\`) remain in the codebase.
- **Line endings**: Confirm that any file I/O operations handle both `\r\n` and `\n` correctly.
- **Case sensitivity**: Linux file systems are case-sensitive. Verify that all file and directory references use consistent casing.
- **Registry and Windows APIs**: Search the codebase for any remaining calls to `Microsoft.Win32` or P/Invoke signatures targeting Windows-only system libraries.

## 5. Check Target Framework Compatibility

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to a supported cross-platform version, such as:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Avoid `net48` or other Windows-only target monikers unless that project is intentionally Windows-only.

## 6. Review NuGet Package Versions

Run the following to identify outdated or vulnerable packages:

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

Update packages where appropriate, particularly those that previously had .NET Framework-specific versions and now have cross-platform equivalents.

## 7. Perform a Runtime Smoke Test

Run the application on each target platform (Windows, Linux, macOS as applicable) and exercise the core functionality. Pay particular attention to:

- Configuration file loading
- Database connections
- Any serialization or reflection-heavy code paths

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific platform, use:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) for your target environment.