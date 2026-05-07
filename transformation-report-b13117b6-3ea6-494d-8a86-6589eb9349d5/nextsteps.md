# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and deploy your migrated project.

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

If a test project exists in the solution, execute the test suite to verify runtime behavior:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any test failures before proceeding. Pay particular attention to tests covering database access, file I/O, or platform-specific behavior, as these areas are most commonly affected by cross-platform migrations.

## 5. Validate Platform-Specific Behavior

Since this is a cross-platform migration, manually verify the following areas at runtime:

- **File paths**: Ensure no hardcoded Windows-style paths (e.g., `C:\`) remain in the code.
- **Registry access**: Any use of `Microsoft.Win32.Registry` will not function on Linux or macOS.
- **Windows-only APIs**: Search the codebase for references to `System.Windows`, `System.Drawing` (GDI+), or COM interop, which may require replacement or conditional compilation.
- **Line endings and encoding**: Confirm that file read/write operations handle line endings correctly across platforms.

## 6. Test on Target Platform

If the intended deployment target is Linux or macOS, run the application on that platform directly to catch any runtime exceptions that would not appear on Windows:

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier (e.g., `win-x64`, `osx-x64`) as needed. Review the contents of the `publish` output folder before deploying to confirm all required assets are present.