# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility analyzers, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests should be investigated to determine whether they reflect a regression introduced during migration or a pre-existing issue.

## 4. Verify Target Framework

Open each `.csproj` file and confirm that the `<TargetFramework>` element references the intended cross-platform .NET version (e.g., `net8.0`). Ensure no projects still reference `net48` or other Windows-only frameworks unless that is intentional.

## 5. Check for Windows-Specific APIs

Use the .NET Compatibility Analyzer or review the code manually for any usage of Windows-specific APIs such as:

- `System.Windows.Forms`
- `System.Drawing` (GDI+ based)
- `Microsoft.Win32` registry access
- COM interop

If any are found, evaluate whether a cross-platform alternative exists or whether the `<SupportedOSPlatform>` attribute should be applied.

## 6. Review Configuration and File Paths

Ensure that any hardcoded file paths use `Path.Combine` or `Path.DirectorySeparatorChar` rather than backslashes, which are Windows-specific. Verify that configuration files (e.g., `appsettings.json`) are correctly structured for the new hosting model if this is an ASP.NET Core project.

## 7. Test on Target Platforms

Run and validate the application on each platform you intend to support (e.g., Windows, Linux, macOS):

```bash
dotnet run --configuration Release
```

Pay attention to runtime exceptions that would not surface at build time, such as platform-specific behavior differences in file I/O, culture handling, or threading.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate RID for your deployment target. Use `--self-contained true` if you require the .NET runtime to be bundled with the output.