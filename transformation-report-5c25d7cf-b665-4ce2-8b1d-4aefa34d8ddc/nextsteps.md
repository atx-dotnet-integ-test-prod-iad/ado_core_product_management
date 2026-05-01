# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and deploy your migrated project.

## 1. Validate the Project Structure

- Confirm that all `.csproj` files have been updated to use the SDK-style format (e.g., `<Project Sdk="Microsoft.NET.Sdk">`).
- Check that `TargetFramework` (or `TargetFrameworks`) is set to the intended cross-platform .NET version (e.g., `net8.0`).
- Verify that no legacy `packages.config` files remain. All NuGet dependencies should be expressed as `<PackageReference>` elements inside the `.csproj` files.
- Confirm that any removed `AssemblyInfo.cs` properties (such as `AssemblyVersion`) are either handled by the `.csproj` directly or intentionally preserved.

## 2. Restore and Build

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release
```

Review test results carefully. Pay attention to any tests that were previously passing and are now failing, as these may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Runtime Compatibility Issues

Even with a clean build, certain APIs behave differently or are unavailable on cross-platform .NET. Review the following areas:

- **Windows-specific APIs**: If the application uses APIs such as the Windows Registry, `System.Windows.Forms`, or COM interop, these will only function on Windows. Use `RuntimeInformation.IsOSPlatform` guards where appropriate.
- **Configuration**: Legacy `System.Configuration.ConfigurationManager` usage may require the `System.Configuration.ConfigurationManager` NuGet package.
- **Reflection and serialization**: Some reflection-based or binary serialization patterns (e.g., `BinaryFormatter`) are disabled or removed in modern .NET. Replace `BinaryFormatter` with a supported alternative such as `System.Text.Json` or `MessagePack`.
- **Thread and culture behavior**: Verify that any globalization-sensitive logic behaves correctly. If the application was built with `<InvariantGlobalization>true</InvariantGlobalization>`, some culture-specific operations may return different results.

## 5. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime errors that would not appear at build time.

```bash
dotnet run --configuration Release
```

## 6. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

**Framework-dependent (requires .NET runtime installed on target machine):**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (bundles the runtime with the application):**
```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier for your target platform (e.g., `win-x64`, `osx-x64`, `osx-arm64`).

## 7. Review Published Output

After publishing, inspect the output directory to confirm:

- All expected assemblies and dependencies are present.
- Configuration files (e.g., `appsettings.json`) are included and correctly structured.
- No unintended files from the legacy project have been carried over.